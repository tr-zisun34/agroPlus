"""Seed the crop_economics table by joining BAMIS district-level yield data with the DAM
price table already produced by clean_dam_prices.py.

BAMIS (Bangladesh Agro-Meteorological Information System) gives, per district, a yield range
(Ton/Ha) plus an estimated cost and profit range (BDT/Bigha) per crop. BAMIS publishes separate
workbooks per crop group (cereals/fiber/fruit, pulses, ...) — pass all of them via --xlsx and
this script scans every sheet in each for the ones it recognizes. Only sheets that map to our
22-crop ML vocabulary are used — Rice_Boro, Rice_Aman, Maize, Lentil, Jute, Mango, Chickpea,
Mungbean, Blackgram. Sheets for crops our recommender can never output (Wheat, Potato, Mustard,
Onion, Garlic, Tomato, Brinjal) are cut rather than imported.

For rice/maize/lentil/chickpea/mungbean/blackgram we already have DAM prices per market variety
(see docs/dataset/crop_prices_cleaned.csv) — this script pairs that price with the matching
BAMIS yield. None of these crops have a per-variety yield breakdown in BAMIS, so one yield
figure is applied to every DAM-priced variety under that crop (e.g. Rice_Aman's yield to all 6
amon_* price varieties); that's a known granularity mismatch (price is market-grade-specific,
yield isn't) — acceptable since the ML model never outputs a variety anyway, only a generic
crop name.

For jute and mango, DAM has no price in our crop vocabulary at all. Instead of leaving them
profit-less, we back out an implied price from BAMIS's own self-consistent
profit = yield * price - cost model: price = (profit + cost) / yield. That keeps our schema
(which always stores price_bdt_per_kg) uniform instead of adding a separate code path.

Also persists BAMIS's own bundled per-acre cost estimate (seed + fertilizer + labor +
irrigation, not broken out) and its cultivation-season text, plus a seed cost per acre from
the BADC/DAM seed price workbook (--seed-prices) — all needed for the per-crop harvest detail
view. cost_bdt_per_acre is what net profit is computed against now, not the farmer's budget.

Fertilizer cost is itemized for real rather than left inside BAMIS's lump cost: BAMIS gives a
per-crop fertilizer recipe (e.g. "Urea: 240kg, TSP: 110kg, ...") and --fertilizer-prices (from
clean_dam_prices.py) gives a real BDT/kg for each input — multiplying the two gives an actual
sourced fertilizer cost, stored both as a total and as a per-input breakdown. Whatever's left
of BAMIS's bundled total after subtracting seed and fertilizer (labor, irrigation, land prep —
things neither BAMIS nor DAM price out individually) is stored as other_cost_bdt_per_acre so
seed + fertilizer + other always reconciles exactly to BAMIS's total.

Usage:
    python seed_crop_economics.py --xlsx "../docs/dataset/BAMIS_District_Wise_Crop_Data_Bangladesh.xlsx" "../docs/dataset/BAMIS_Pulse_Crops_District_Wise_Data_Bangladesh.xlsx" --prices "../docs/dataset/crop_prices_cleaned.csv" --seed-prices "../docs/dataset/Specified_Crops_Seed_Prices_BADC_DAM.xlsx" --fertilizer-prices "../docs/dataset/fertilizer_prices_cleaned.csv"
"""

import argparse
import csv
import datetime
import pathlib

import openpyxl
from sqlalchemy.dialects.postgresql import insert

from app.db.session import SessionLocal
from app.models.crop_economics import CropEconomics

# BAMIS fertilizer recipe label -> our fertilizer_prices_cleaned.csv input key.
FERTILIZER_RECIPE_NAME_MAP = {
    "urea": "urea",
    "tsp": "tsp",
    "dap": "dap",
    "mop": "mop",
    "gypsum": "gypsum",
    "zinc": "zinc",
}

HA_TO_ACRE = 2.47105
BIGHA_TO_ACRE = 0.33  # Bangladesh convention: 1 acre = 100 decimal, 1 bigha = 33 decimal

# sheet name -> (crop, [price-table varieties this yield figure applies to])
# "" means the crop has no variety split (maize/jute/mango are single-entity in our price table
# — jute/mango have no DAM price row at all, so "" just means "the one row for this crop").
SHEET_TO_VARIETIES = {
    "Rice_Boro": ("rice", ["boro_medium"]),
    "Rice_Aman": (
        "rice",
        [
            "amon_local_medium",
            "amon_local_coarse",
            "amon_local_fine",
            "amon_pajam",
            "amon_aromatic",
            "amon_hybrid_medium",
            "amon_hybrid_coarse",
        ],
    ),
    "Maize": ("maize", [""]),
    "Lentil": ("lentil", ["domestic_split", "domestic_whole", "imported_premium", "imported_standard"]),
    "Jute": ("jute", [""]),
    "Mango": ("mango", [""]),
    "Chickpea": ("chickpea", ["domestic_premium", "imported", "split_domestic", "whole_domestic"]),
    "Mungbean": ("mungbean", ["domestic", "imported", "small_domestic_premium"]),
    "Blackgram": ("blackgram", ["split", "whole", "whole_domestic"]),
}
CROPS_WITHOUT_DAM_PRICE = {"jute", "mango"}

# BAMIS season-text keyword -> one of Bangladesh's three growing seasons (same values as
# Farm.target_season). Kharif-1/Kharif-2 are BAMIS's own names for Aus/Aman.
SEASON_KEYWORDS = {
    "Kharif-2": "Aman",
    "Kharif-1": "Aus",
    "Rabi": "Rabi",
    "Boro": "Rabi",
    "Aman": "Aman",
    "Aus": "Aus",
}


def classify_season(season_label: str | None) -> str | None:
    """Classify BAMIS's free-text cultivation season into Rabi/Aus/Aman by keyword. Several
    crops have dual-season text (e.g. mungbean's "Kharif-1 / Rabi (Feb - May)") — the
    earliest-mentioned season wins, since BAMIS lists the primary season first. Returns None
    when nothing matches (e.g. Mango's "Perennial (May - Jul)") — expected, since perennial
    crops aren't candidates for the seasonal multi-cropping planner anyway."""
    if not season_label:
        return None
    best_position, best_season = None, None
    for keyword, season in SEASON_KEYWORDS.items():
        position = season_label.find(keyword)
        if position != -1 and (best_position is None or position < best_position):
            best_position, best_season = position, season
    return best_season


def midpoint(range_str: str) -> float:
    low, high = range_str.replace(",", "").split("-")
    return (float(low.strip()) + float(high.strip())) / 2


def load_bamis_national_averages(xlsx_paths: list[pathlib.Path]) -> dict[str, dict]:
    """BAMIS publishes separate workbooks per crop group (cereals/fiber/fruit in one file,
    pulses in another, etc.) — scan every sheet in every given workbook and keep whichever
    ones match a crop we know how to use; sheets for crops outside our vocabulary are skipped."""
    results = {}
    for xlsx_path in xlsx_paths:
        wb = openpyxl.load_workbook(xlsx_path, data_only=True)

        season_by_sheet = {}
        overview_rows = wb["Overview & Summary"].iter_rows(min_row=4, values_only=True)
        for row in overview_rows:
            if row and row[0] in SHEET_TO_VARIETIES:
                season_by_sheet[row[0]] = row[2]

        for sheet_name in wb.sheetnames:
            if sheet_name not in SHEET_TO_VARIETIES:
                continue
            ws = wb[sheet_name]
            rows = list(ws.iter_rows(min_row=4, max_row=ws.max_row, values_only=True))
            rows = [r for r in rows if r and r[0]]

            yields_ton_ha = [midpoint(r[7]) for r in rows]
            costs_bdt_bigha = [midpoint(r[8]) for r in rows]
            profits_bdt_bigha = [midpoint(r[9]) for r in rows]

            avg_yield_ton_ha = sum(yields_ton_ha) / len(yields_ton_ha)
            avg_cost_bdt_bigha = sum(costs_bdt_bigha) / len(costs_bdt_bigha)
            avg_profit_bdt_bigha = sum(profits_bdt_bigha) / len(profits_bdt_bigha)

            results[sheet_name] = {
                "yield_kg_per_acre": avg_yield_ton_ha * 1000 / HA_TO_ACRE,
                "cost_bdt_per_acre": avg_cost_bdt_bigha / BIGHA_TO_ACRE,
                "profit_bdt_per_acre": avg_profit_bdt_bigha / BIGHA_TO_ACRE,
                "season_label": season_by_sheet.get(sheet_name),
                # Fertilizer Recommendation (per Ha) — constant across districts for a crop,
                # so the first district's value is representative.
                "fertilizer_recipe_text": rows[0][10],
                "district_count": len(rows),
            }

    missing = set(SHEET_TO_VARIETIES) - set(results)
    if missing:
        raise ValueError(f"Missing BAMIS sheets in the given workbooks: {sorted(missing)}")
    return results


def load_dam_prices(csv_path: pathlib.Path) -> dict[tuple[str, str], float]:
    prices = {}
    with csv_path.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            prices[(row["crop"], row["variety"])] = float(row["wholesale_bdt_per_kg"])
    return prices


def parse_fertilizer_recipe(text: str) -> dict[str, float]:
    """'Urea: 240kg, TSP: 110kg, MoP: 110kg, Gypsum: 65kg, Zinc: 10kg' -> {'urea': 240.0, ...}
    (kg per hectare). Handles ranges ('40-50kg' -> midpoint). Entries we don't have a DAM price
    for (Boron, Rhizobium/Bio-fertilizer) are skipped, not guessed at. Mango's recipe is priced
    per tree ('1.8kg/tree'), not per hectare — fundamentally a different unit basis we can't
    convert without a trees-per-acre density we don't have, so those are skipped entirely."""
    recipe = {}
    for part in text.split(","):
        part = part.strip()
        if ":" not in part:
            continue
        name, qty_str = part.split(":", 1)
        fert_type = FERTILIZER_RECIPE_NAME_MAP.get(name.strip().lower())
        if fert_type is None:
            continue

        qty_str = qty_str.strip()
        if "/tree" in qty_str:
            continue
        qty_str = qty_str.replace("kg/ha", "").replace("kg", "").strip()

        if "-" in qty_str:
            low, high = qty_str.split("-")
            qty = (float(low.strip()) + float(high.strip())) / 2
        else:
            try:
                qty = float(qty_str)
            except ValueError:
                continue
        recipe[fert_type] = qty
    return recipe


def load_fertilizer_prices(csv_path: pathlib.Path) -> dict[str, float]:
    prices = {}
    with csv_path.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            prices[row["fertilizer"]] = float(row["bdt_per_kg"])
    return prices


def load_seed_costs(xlsx_path: pathlib.Path) -> dict[str, float]:
    """BADC/DAM seed price workbook: one row per crop with 'Estimated Seed Cost / Bigha (BDT)'
    already computed (seed price x seed rate) as a range — just convert to BDT/acre. Match by
    the crop name's ASCII prefix (e.g. 'Chickpea (ছোলা)' -> 'chickpea') rather than the full
    string, to sidestep any Bengali Unicode normalization mismatch between the source file and
    hand-typed literals here."""
    wb = openpyxl.load_workbook(xlsx_path, data_only=True)
    ws = wb["Seed_Prices_&_Economics"]
    rows = list(ws.iter_rows(min_row=5, max_row=ws.max_row, values_only=True))

    result = {}
    for row in rows:
        if not row or not row[0]:
            continue
        crop = row[0].split("(")[0].strip().lower()
        seed_cost_bdt_bigha = midpoint(row[4])
        result[crop] = seed_cost_bdt_bigha / BIGHA_TO_ACRE
    return result


def compute_fertilizer_cost(
    figures: dict, fertilizer_prices: dict[str, float]
) -> tuple[float, dict]:
    """Returns (total_fertilizer_cost_bdt_per_acre, breakdown) where breakdown maps each
    fertilizer input to its own quantity/price/cost — the itemization the harvest detail
    screen shows."""
    recipe = parse_fertilizer_recipe(figures["fertilizer_recipe_text"])
    breakdown = {}
    total = 0.0
    for fert_type, qty_kg_per_ha in recipe.items():
        price = fertilizer_prices.get(fert_type)
        if price is None:
            continue
        qty_kg_per_acre = qty_kg_per_ha / HA_TO_ACRE
        cost = qty_kg_per_acre * price
        breakdown[fert_type] = {
            "qty_kg_per_acre": round(qty_kg_per_acre, 2),
            "price_bdt_per_kg": price,
            "cost_bdt_per_acre": round(cost, 2),
        }
        total += cost
    return total, breakdown


def build_rows(
    bamis: dict[str, dict],
    prices: dict[tuple[str, str], float],
    seed_costs: dict[str, float],
    fertilizer_prices: dict[str, float],
) -> list[dict]:
    today = datetime.date.today()
    rows = []
    for sheet_name, (crop, varieties) in SHEET_TO_VARIETIES.items():
        figures = bamis[sheet_name]

        fertilizer_cost, fertilizer_breakdown = compute_fertilizer_cost(figures, fertilizer_prices)
        seed_cost = seed_costs.get(crop)
        total_cost = figures["cost_bdt_per_acre"]
        other_cost = total_cost - (seed_cost or 0) - fertilizer_cost
        if other_cost < 0:
            print(
                f"  warning: {crop} seed+fertilizer cost ({(seed_cost or 0) + fertilizer_cost:.2f}) exceeds "
                f"BAMIS total cost ({total_cost:.2f}) — clamping other_cost to 0"
            )
            other_cost = 0.0

        for variety in varieties:
            if crop in CROPS_WITHOUT_DAM_PRICE:
                price = (figures["profit_bdt_per_acre"] + figures["cost_bdt_per_acre"]) / figures["yield_kg_per_acre"]
                source = "BAMIS (yield, cost) + implied price from BAMIS cost/profit model"
            else:
                price = prices.get((crop, variety))
                if price is None:
                    print(f"  skipping {crop}/{variety!r}: no DAM price row for this variety")
                    continue
                source = "BAMIS (yield, cost) + DAM (wholesale price)"

            if seed_cost is not None:
                source += " + BADC/DAM (seed cost)"
            if fertilizer_breakdown:
                source += " + BAMIS recipe x DAM (fertilizer cost)"

            rows.append(
                {
                    "crop": crop,
                    "variety": variety,
                    "yield_kg_per_acre": round(figures["yield_kg_per_acre"], 2),
                    "price_bdt_per_kg": round(price, 2),
                    "cost_bdt_per_acre": round(total_cost, 2),
                    "seed_cost_bdt_per_acre": round(seed_cost, 2) if seed_cost is not None else None,
                    "fertilizer_cost_bdt_per_acre": round(fertilizer_cost, 2) if fertilizer_breakdown else None,
                    "fertilizer_breakdown": fertilizer_breakdown or None,
                    "other_cost_bdt_per_acre": round(other_cost, 2),
                    "season_label": figures["season_label"],
                    "season": classify_season(figures["season_label"]),
                    "source": source,
                    "as_of_date": today,
                }
            )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--xlsx", required=True, nargs="+", help="Path(s) to one or more BAMIS district-wise crop data workbooks"
    )
    parser.add_argument("--prices", required=True, help="Path to clean_dam_prices.py's output CSV")
    parser.add_argument("--seed-prices", required=True, help="Path to the BADC/DAM seed price workbook")
    parser.add_argument(
        "--fertilizer-prices", required=True, help="Path to clean_dam_prices.py's --fertilizer-out CSV"
    )
    args = parser.parse_args()

    bamis = load_bamis_national_averages([pathlib.Path(p) for p in args.xlsx])
    prices = load_dam_prices(pathlib.Path(args.prices))
    seed_costs = load_seed_costs(pathlib.Path(args.seed_prices))
    fertilizer_prices = load_fertilizer_prices(pathlib.Path(args.fertilizer_prices))
    rows = build_rows(bamis, prices, seed_costs, fertilizer_prices)

    db = SessionLocal()
    try:
        for row in rows:
            stmt = (
                insert(CropEconomics)
                .values(**row)
                .on_conflict_do_update(index_elements=["crop", "variety"], set_=row)
            )
            db.execute(stmt)
        db.commit()
    finally:
        db.close()

    print(f"Seeded {len(rows)} crop_economics rows:")
    for row in rows:
        print(
            f"  {row['crop']:10s} {row['variety']:25s} yield={row['yield_kg_per_acre']:>9} kg/acre  "
            f"price={row['price_bdt_per_kg']:>8} BDT/kg  total_cost={row['cost_bdt_per_acre']:>9} BDT/acre  "
            f"seed={row['seed_cost_bdt_per_acre']!s:>9}  fertilizer={row['fertilizer_cost_bdt_per_acre']!s:>9}  "
            f"other={row['other_cost_bdt_per_acre']!s:>9}  season={row['season_label']}"
        )


if __name__ == "__main__":
    main()
