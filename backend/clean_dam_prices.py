"""Clean and format a DAM "product-wise market price report" CSV into the crop/variety
price table our app actually uses.

The raw DAM export is a nationwide report template: a dozen preamble rows (division/
district/upazila/market catalogs, product catalog, year, month, week), then one row per
market x product with retail and wholesale price ranges + DAM's own precomputed averages.
We only care about a short list of our 22 ML crops, want paddy varieties kept as distinct
entities (never averaged into one generic "rice" price), and need everything normalized to
BDT/kg so it can later be joined with yield (kg/acre) to compute net profit.

Also optionally extracts fertilizer input prices (Urea/TSP/DAP/MoP/Gypsum/Zinc, brand/origin
variants collapsed to one national average per input, since brand doesn't affect a cost
estimate the way crop variety affects a selling price) — used to cost out BAMIS's per-crop
fertilizer recipe into a real itemized fertilizer cost rather than a lump estimate.

Usage:
    python clean_dam_prices.py --data "docs/dataset/product-wise-market-price-report (...).csv" --out docs/dataset/crop_prices_cleaned.csv --fertilizer-out docs/dataset/fertilizer_prices_cleaned.csv

Unmapped products (onion, potato, tobacco, spices, fruit we don't have yield data for, etc.)
are silently dropped — that's the "cut off what we don't know" step.
"""

import argparse
import csv
import pathlib
import statistics
import unicodedata

BN_DIGITS = "০১২৩৪৫৬৭৮৯"
BN_TO_ASCII = {bn: str(i) for i, bn in enumerate(BN_DIGITS)}

# DAM product name (Bangla) -> (crop, variety). Only entities we've confirmed are real BD
# field crops with usable kg-based pricing. Paddy (ধান) is used rather than milled rice
# (চাল) since BBS yield figures are reported at the paddy/field stage, not post-milling.
PRODUCT_MAP = {
    "ধান - আমন - দেশীয় - মাঝারি": ("rice", "amon_local_medium"),
    "ধান - আমন - দেশীয় - মোটা": ("rice", "amon_local_coarse"),
    "ধান - আমন - দেশীয় - সরু": ("rice", "amon_local_fine"),
    "ধান - আমন - পাজাম": ("rice", "amon_pajam"),
    "ধান - আমন - সুগন্ধি (পোলাও)": ("rice", "amon_aromatic"),
    "ধান - আমন - হাইব্রিড - মাঝারি": ("rice", "amon_hybrid_medium"),
    "ধান - আমন - হাইব্রিড - মোটা": ("rice", "amon_hybrid_coarse"),
    "ধান-মাঝারী-বোরো": ("rice", "boro_medium"),
    "ভুট্টা": ("maize", None),
    "ছোলা (আমদানীকৃত)": ("chickpea", "imported"),
    "ছোলা (আস্ত)": ("chickpea", "whole_domestic"),
    "ছোলা (ভাঙা)": ("chickpea", "split_domestic"),
    "ছোলা দেশী-উন্নতমানের": ("chickpea", "domestic_premium"),
    "ছোট মুগ ডাল (দেশি) - উন্নত মানের": ("mungbean", "small_domestic_premium"),
    "মুগ ডাল (আমদানিকৃত)": ("mungbean", "imported"),
    "মুগ ডাল (দেশি)": ("mungbean", "domestic"),
    "মাশ কালাই (আস্ত)": ("blackgram", "whole"),
    "মাশ কালাই (আস্ত) দেশি": ("blackgram", "whole_domestic"),
    "মাশ কালাই (ভাঙা)": ("blackgram", "split"),
    "মশুর (আমদানীকৃত) উন্নতমানের": ("lentil", "imported_premium"),
    "মশুর (আমদানীকৃত) সাধারণ মান": ("lentil", "imported_standard"),
    "মসুর ডাল -দেশি-আস্ত": ("lentil", "domestic_whole"),
    "মসুর ডাল -দেশি-ভাঙ্গা": ("lentil", "domestic_split"),
}
# DAM's export and this file can mix precomposed/decomposed Bengali characters (e.g. য়
# as one codepoint vs য + a combining nukta) that look identical but compare unequal —
# normalize both the map and incoming product names to NFC before matching.
PRODUCT_MAP = {unicodedata.normalize("NFC", k): v for k, v in PRODUCT_MAP.items()}

# Per-unit divisor to convert a price into BDT/kg. Units not listed here (piece counts,
# bags, bundles) aren't resolvable to a per-kg price without a weight assumption we don't
# have yet, so rows using them are dropped rather than guessed at.
UNIT_TO_KG_DIVISOR = {
    "কিলোগ্রাম": 1,
    "১ কেজি": 1,
    "কুইন্টাল": 100,
}

# DAM product name (Bangla, brand/origin variants collapsed) -> our fertilizer input type.
# Unlike crop varieties, brand doesn't matter for a cost estimate, so every Urea/TSP/etc.
# brand or import-source variant is averaged into one national price per input — this feeds
# BAMIS's "Urea: 240kg, TSP: 110kg, ..." per-crop fertilizer recipe to compute real cost.
FERTILIZER_MAP = {
    "রাসায়নিক সার - ইউরিয়া (কাফকো)": "urea",
    "রাসায়নিক সার - ইউরিয়া (যমুনা)": "urea",
    "রাসায়নিক সার - ইউরিয়া (ঘোড়াশাল)": "urea",
    "রাসায়নিক সার - ইউরিয়া (জিয়া)": "urea",
    "রাসায়নিক সার- টি, এস, পি(আমদানীকৃত)": "tsp",
    "রাসায়নিক সার- টি, এস, পি-(দেশীয়)": "tsp",
    "রাসায়নিক সার- ডি, এ, পি": "dap",
    "রাসায়নিক সার- এ, ম, পি(আমদানীকৃত) - চীন": "mop",
    "রাসায়নিক সার- এ, ম, পি(আমদানীকৃত) - রাশিয়া": "mop",
    "রাসায়নিক সার- জিপসাম(আমদানীকৃত)": "gypsum",
    "রাসায়নিক সার- জিপসাম(দেশীয়)": "gypsum",
    "রাসায়নিক সার- দস্তা- (আমদানীকৃত)": "zinc",
    "রাসায়নিক সার- দস্তা- দেশীয়": "zinc",
}
FERTILIZER_MAP = {unicodedata.normalize("NFC", k): v for k, v in FERTILIZER_MAP.items()}

OUTLIER_LOW_RATIO = 0.25
OUTLIER_HIGH_RATIO = 4.0


def bn_number(raw: str) -> float | None:
    """Parse a DAM number cell (Bangla digits, comma grouping) to a float, or None if blank/zero."""
    raw = raw.strip()
    if not raw:
        return None
    ascii_str = "".join(BN_TO_ASCII.get(ch, ch) for ch in raw)
    ascii_str = ascii_str.replace(",", "")
    try:
        value = float(ascii_str)
    except ValueError:
        return None
    return value if value > 0 else None


def find_header_row(rows: list[list[str]]) -> int:
    for i, row in enumerate(rows):
        if row and row[0].strip() == "বিভাগ" and "পণ্য নাম" in row:
            return i
    raise ValueError("Could not locate the 'বিভাগ' header row in this DAM export")


def load_rows(path: pathlib.Path) -> list[dict]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        raw_rows = list(csv.reader(f))

    header_idx = find_header_row(raw_rows)
    records = []
    for row in raw_rows[header_idx + 1 :]:
        if not row or not row[0].strip():
            continue
        division, district, _upazila, market, product, _year, retail_unit, _retail_range, \
            retail_avg, wholesale_unit, _wholesale_range, wholesale_avg = row[:12]

        mapping = PRODUCT_MAP.get(unicodedata.normalize("NFC", product.strip()))
        if mapping is None:
            continue
        crop, variety = mapping

        retail_divisor = UNIT_TO_KG_DIVISOR.get(retail_unit.strip())
        wholesale_divisor = UNIT_TO_KG_DIVISOR.get(wholesale_unit.strip())
        if wholesale_divisor is None:
            continue  # can't normalize this row's main price signal to per-kg

        retail_val = bn_number(retail_avg)
        wholesale_val = bn_number(wholesale_avg)
        if wholesale_val is None:
            continue

        records.append(
            {
                "crop": crop,
                "variety": variety,
                "product_bn": product.strip(),
                "district": district.strip(),
                "market": market.strip(),
                "division": division.strip(),
                "retail_bdt_per_kg": (retail_val / retail_divisor) if (retail_val and retail_divisor) else None,
                "wholesale_bdt_per_kg": wholesale_val / wholesale_divisor,
            }
        )
    return records


def load_fertilizer_rows(path: pathlib.Path) -> list[dict]:
    """Fertilizer is bought at retail (farmers aren't buying wholesale bags), and its retail
    unit is already কিলোগ্রাম — no quintal-style conversion needed, unlike crop prices."""
    with path.open(encoding="utf-8-sig", newline="") as f:
        raw_rows = list(csv.reader(f))

    header_idx = find_header_row(raw_rows)
    records = []
    for row in raw_rows[header_idx + 1 :]:
        if not row or not row[0].strip():
            continue
        division, district, _upajila, market, product, _year, retail_unit, _retail_range, \
            retail_avg, *_rest = row[:12]

        fert_type = FERTILIZER_MAP.get(unicodedata.normalize("NFC", product.strip()))
        if fert_type is None:
            continue

        divisor = UNIT_TO_KG_DIVISOR.get(retail_unit.strip())
        if divisor is None:
            continue

        price = bn_number(retail_avg)
        if price is None:
            continue

        records.append(
            {
                "fertilizer": fert_type,
                "product_bn": product.strip(),
                "district": district.strip(),
                "market": market.strip(),
                "division": division.strip(),
                "bdt_per_kg": price / divisor,
            }
        )
    return records


def drop_fertilizer_outliers(records: list[dict]) -> list[dict]:
    by_fert: dict[str, list[dict]] = {}
    for r in records:
        by_fert.setdefault(r["fertilizer"], []).append(r)

    kept = []
    for fert_rows in by_fert.values():
        values = [r["bdt_per_kg"] for r in fert_rows]
        median = statistics.median(values)
        for r in fert_rows:
            v = r["bdt_per_kg"]
            if median * OUTLIER_LOW_RATIO <= v <= median * OUTLIER_HIGH_RATIO:
                kept.append(r)
            else:
                print(f"  dropped fertilizer outlier: {r['product_bn']} in {r['district']} — {v} BDT/kg vs median {median}")
    return kept


def aggregate_fertilizer(records: list[dict]) -> list[dict]:
    groups: dict[str, list[dict]] = {}
    for r in records:
        groups.setdefault(r["fertilizer"], []).append(r)

    rows = []
    for fert_type, group in sorted(groups.items()):
        values = [r["bdt_per_kg"] for r in group]
        rows.append(
            {
                "fertilizer": fert_type,
                "bdt_per_kg": round(sum(values) / len(values), 2),
                "sample_count": len(group),
                "districts": ";".join(sorted({r["district"] for r in group})),
            }
        )
    return rows


def drop_outliers(records: list[dict]) -> list[dict]:
    """Drop rows whose wholesale price is way off from the median for the same crop —
    catches the DAM sentinel/typo values (e.g. a stray '9,99,999.99') without hardcoding them.
    Grouped by crop rather than exact variety because several varieties only have a single
    sample row and can't detect their own outliers in isolation; different varieties of the
    same crop still trade in a similar price band."""
    by_crop: dict[str, list[dict]] = {}
    for r in records:
        by_crop.setdefault(r["crop"], []).append(r)

    kept = []
    for crop_rows in by_crop.values():
        values = [r["wholesale_bdt_per_kg"] for r in crop_rows]
        median = statistics.median(values)
        for r in crop_rows:
            v = r["wholesale_bdt_per_kg"]
            if median * OUTLIER_LOW_RATIO <= v <= median * OUTLIER_HIGH_RATIO:
                kept.append(r)
            else:
                print(f"  dropped outlier: {r['product_bn']} in {r['district']} — wholesale {v} BDT/kg vs crop median {median}")
    return kept


def aggregate(records: list[dict]) -> list[dict]:
    groups: dict[tuple[str, str | None], list[dict]] = {}
    for r in records:
        groups.setdefault((r["crop"], r["variety"]), []).append(r)

    rows = []
    for (crop, variety), group in sorted(groups.items()):
        wholesale_vals = [r["wholesale_bdt_per_kg"] for r in group]
        retail_vals = [r["retail_bdt_per_kg"] for r in group if r["retail_bdt_per_kg"] is not None]
        rows.append(
            {
                "crop": crop,
                "variety": variety or "",
                "product_bn": group[0]["product_bn"],
                "wholesale_bdt_per_kg": round(sum(wholesale_vals) / len(wholesale_vals), 2),
                "retail_bdt_per_kg": round(sum(retail_vals) / len(retail_vals), 2) if retail_vals else "",
                "sample_count": len(group),
                "districts": ";".join(sorted({r["district"] for r in group})),
            }
        )
    return rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", required=True, help="Path to a raw DAM product-wise price report CSV")
    parser.add_argument("--out", required=True, help="Output path for the cleaned crop price CSV")
    parser.add_argument("--fertilizer-out", help="Output path for the cleaned fertilizer price CSV (optional)")
    args = parser.parse_args()

    records = load_rows(pathlib.Path(args.data))
    records = drop_outliers(records)
    rows = aggregate(records)

    out_path = pathlib.Path(args.out)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["crop", "variety", "product_bn", "wholesale_bdt_per_kg", "retail_bdt_per_kg", "sample_count", "districts"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} crop/variety price entities to {out_path.resolve()}")
    for row in rows:
        print(f"  {row['crop']:10s} {row['variety']:25s} wholesale={row['wholesale_bdt_per_kg']:>8} retail={row['retail_bdt_per_kg']!s:>8} (n={row['sample_count']})")

    if args.fertilizer_out:
        fert_records = load_fertilizer_rows(pathlib.Path(args.data))
        fert_records = drop_fertilizer_outliers(fert_records)
        fert_rows = aggregate_fertilizer(fert_records)

        fert_out_path = pathlib.Path(args.fertilizer_out)
        with fert_out_path.open("w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["fertilizer", "bdt_per_kg", "sample_count", "districts"])
            writer.writeheader()
            writer.writerows(fert_rows)

        print(f"\nWrote {len(fert_rows)} fertilizer price entities to {fert_out_path.resolve()}")
        for row in fert_rows:
            print(f"  {row['fertilizer']:10s} price={row['bdt_per_kg']:>8} BDT/kg (n={row['sample_count']})")


if __name__ == "__main__":
    main()
