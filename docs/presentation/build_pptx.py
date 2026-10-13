"""Builds AgroPlus_Presentation.pptx — a full, editable slide deck for the project defense.

Run from docs/presentation/:
    ..\\..\\backend\\.venv\\Scripts\\python build_pptx.py
"""

import pathlib

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

HERE = pathlib.Path(__file__).resolve().parent
IMAGES = HERE.parent / "report" / "images"
OUT = HERE / "AgroPlus_Presentation.pptx"

# ---------------------------------------------------------------- palette ---
DARK = "1B4332"
MID = "2D6A4F"
LIGHT_BG = "EEF5EA"
CARD_BG = "FFFFFF"
CARD_BORDER = "DBE8D6"
AMBER = "B7791F"
AMBER_BG = "FDF3E3"
BLUE = "1B2B6B"
BLUE_BG = "EEF2FB"
TEAL = "0C4A6E"
TEAL_BG = "EEF7FB"
PINK = "7A1F49"
PINK_BG = "FAF0F5"
TEXT_DARK = "15351F"
TEXT_BODY = "3F5E49"
TEXT_MUTED = "5A7563"
WHITE = "FFFFFF"

FONT = "Segoe UI"

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height
BLANK = prs.slide_layouts[6]


def rgb(hexstr):
    return RGBColor.from_string(hexstr)


def new_slide(bg=LIGHT_BG):
    slide = prs.slides.add_slide(BLANK)
    bgshape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SW, SH)
    bgshape.fill.solid()
    bgshape.fill.fore_color.rgb = rgb(bg)
    bgshape.line.fill.background()
    bgshape.shadow.inherit = False
    # send to back is automatic (first shape added)
    return slide


def add_rect(slide, x, y, w, h, fill=None, line=None, line_w=1.0, rounded=True, shadow=False):
    shape_type = MSO_SHAPE.ROUNDED_RECTANGLE if rounded else MSO_SHAPE.RECTANGLE
    shape = slide.shapes.add_shape(shape_type, x, y, w, h)
    if rounded:
        try:
            shape.adjustments[0] = 0.07
        except Exception:
            pass
    if fill:
        shape.fill.solid()
        shape.fill.fore_color.rgb = rgb(fill)
    else:
        shape.fill.background()
    if line:
        shape.line.color.rgb = rgb(line)
        shape.line.width = Pt(line_w)
    else:
        shape.line.fill.background()
    shape.shadow.inherit = False
    return shape


def add_text(slide, x, y, w, h, text, size=14, color=TEXT_DARK, bold=False, italic=False,
             align=PP_ALIGN.LEFT, anchor=MSO_ANCHOR.TOP, font=FONT, line_spacing=1.0, wrap=True):
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = wrap
    tf.vertical_anchor = anchor
    tf.margin_left = 0
    tf.margin_right = 0
    tf.margin_top = 0
    tf.margin_bottom = 0
    lines = text.split("\n")
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        p.line_spacing = line_spacing
        run = p.add_run()
        run.text = line
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.italic = italic
        run.font.name = font
        run.font.color.rgb = rgb(color)
    return box


def add_bullets(slide, x, y, w, h, items, size=13, color=TEXT_BODY, bold_lead=True,
                 bullet_color=MID, gap_pt=10, font=FONT, anchor=MSO_ANCHOR.TOP):
    """items: list of (lead, rest) tuples, or plain strings."""
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left = 0
    tf.margin_right = 0
    for i, item in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = Pt(gap_pt)
        p.line_spacing = 1.12
        r1 = p.add_run()
        r1.text = "✦  "
        r1.font.size = Pt(size)
        r1.font.color.rgb = rgb(bullet_color)
        r1.font.bold = True
        r1.font.name = font
        if isinstance(item, tuple):
            lead, rest = item
            r2 = p.add_run()
            r2.text = lead
            r2.font.size = Pt(size)
            r2.font.bold = bold_lead
            r2.font.color.rgb = rgb(TEXT_DARK)
            r2.font.name = font
            if rest:
                r3 = p.add_run()
                r3.text = rest
                r3.font.size = Pt(size)
                r3.font.color.rgb = rgb(color)
                r3.font.name = font
        else:
            r2 = p.add_run()
            r2.text = item
            r2.font.size = Pt(size)
            r2.font.color.rgb = rgb(color)
            r2.font.name = font
    return box


def add_pill(slide, x, y, w, h, text, fill=CARD_BG, border=CARD_BORDER, text_color=MID, size=11, bold=True):
    shape = add_rect(slide, x, y, w, h, fill=fill, line=border, line_w=1.0, rounded=True)
    try:
        shape.adjustments[0] = 0.5
    except Exception:
        pass
    tf = shape.text_frame
    tf.margin_left = Pt(2)
    tf.margin_right = Pt(2)
    tf.margin_top = Pt(0)
    tf.margin_bottom = Pt(0)
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    r = p.add_run()
    r.text = text
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.name = FONT
    r.font.color.rgb = rgb(text_color)
    return shape


def header(slide, kicker, title, kicker_color=MID):
    add_text(slide, Inches(0.7), Inches(0.42), Inches(8), Inches(0.35), kicker.upper(),
              size=13, color=kicker_color, bold=True)
    add_text(slide, Inches(0.7), Inches(0.72), Inches(11.9), Inches(0.75), title,
              size=30, color=TEXT_DARK, bold=True)
    rule = add_rect(slide, Inches(0.7), Inches(1.42), Inches(1.1), Pt(4), fill=MID, rounded=False)
    return slide


def footer(slide, page_no):
    add_text(slide, Inches(0.7), Inches(7.12), Inches(6), Inches(0.3), "AgroPlus — SE 801 Final Presentation",
              size=9.5, color=TEXT_MUTED)
    add_text(slide, Inches(11.9), Inches(7.12), Inches(0.7), Inches(0.3), str(page_no),
              size=9.5, color=TEXT_MUTED, align=PP_ALIGN.RIGHT)


def add_screenshot(slide, path, x, top, height, border=CARD_BORDER):
    pic = slide.shapes.add_picture(str(path), x, top, height=height)
    # thin border frame behind/around — add a rounded rect outline matching picture bounds
    frame = add_rect(slide, pic.left - Pt(2), pic.top - Pt(2), pic.width + Pt(4), pic.height + Pt(4),
                      fill=None, line=border, line_w=1.25, rounded=True)
    frame.fill.background()
    # move frame behind picture: reorder by removing+reinserting picture after frame
    spTree = slide.shapes._spTree
    spTree.remove(pic._element)
    spTree.append(pic._element)
    return pic


# =====================================================================
# SLIDE 1 — TITLE
# =====================================================================
s = new_slide(bg=LIGHT_BG)
add_rect(s, 0, 0, SW, Inches(0.12), fill=MID, rounded=False)
leaf = add_rect(s, Inches(5.73), Inches(1.15), Inches(1.0), Inches(1.0), fill=MID, rounded=True)
try:
    leaf.adjustments[0] = 0.28
except Exception:
    pass
tf = leaf.text_frame
tf.vertical_anchor = MSO_ANCHOR.MIDDLE
p = tf.paragraphs[0]
p.alignment = PP_ALIGN.CENTER
r = p.add_run()
r.text = "\U0001F331"
r.font.size = Pt(34)

add_text(s, Inches(1.0), Inches(2.35), Inches(11.33), Inches(1.1), "AgroPlus",
          size=56, color=TEXT_DARK, bold=True, align=PP_ALIGN.CENTER)
add_text(s, Inches(1.5), Inches(3.35), Inches(10.33), Inches(0.6),
          "Soil- and Weather-Aware Crop Recommendation & Farm Profitability Platform",
          size=18, color=TEXT_BODY, align=PP_ALIGN.CENTER, italic=True)

add_pill(s, Inches(5.17), Inches(4.05), Inches(3.0), Inches(0.42), "SE 801 · SOFTWARE PROJECT LAB–III",
          fill=MID, border=MID, text_color=WHITE, size=11.5)

add_text(s, Inches(1.5), Inches(5.0), Inches(10.33), Inches(0.4), "Md. Tuuhidur Rahman",
          size=16, color=TEXT_DARK, bold=True, align=PP_ALIGN.CENTER)
add_text(s, Inches(1.5), Inches(5.38), Inches(10.33), Inches(0.35),
          "BSSE Roll 1434  •  Exam Roll 2322144",
          size=12, color=TEXT_MUTED, align=PP_ALIGN.CENTER)
add_text(s, Inches(1.5), Inches(5.9), Inches(10.33), Inches(0.35),
          "Supervised by Dr. Zerina Begum, Professor — Institute of Information Technology, University of Dhaka",
          size=12, color=TEXT_MUTED, align=PP_ALIGN.CENTER)
add_text(s, Inches(1.5), Inches(6.7), Inches(10.33), Inches(0.35), "11 October, 2026",
          size=11, color=TEXT_MUTED, align=PP_ALIGN.CENTER)

# =====================================================================
# SLIDE 2 — AGENDA
# =====================================================================
s = new_slide()
header(s, "Overview", "Agenda")
agenda = [
    "Problem Statement",
    "Our Solution",
    "Feature Overview",
    "Tech Stack & System Architecture",
    "Feature Deep-Dives — Recommendation, Profit, Rotation, AI Assistant",
    "Live App Walkthrough (Screenshots)",
    "Data Model, Testing & Verification",
    "Known Limitations & Future Work",
]
colw = Inches(5.7)
col1x, col2x = Inches(0.9), Inches(7.0)
y = Inches(2.1)
for i, item in enumerate(agenda):
    col_x = col1x if i < 4 else col2x
    row = i if i < 4 else i - 4
    num = add_rect(s, col_x, y + Inches(1.1 * row), Inches(0.5), Inches(0.5), fill=MID, rounded=True)
    try:
        num.adjustments[0] = 0.5
    except Exception:
        pass
    ntf = num.text_frame
    ntf.vertical_anchor = MSO_ANCHOR.MIDDLE
    np = ntf.paragraphs[0]
    np.alignment = PP_ALIGN.CENTER
    nr = np.add_run()
    nr.text = str(i + 1)
    nr.font.size = Pt(16)
    nr.font.bold = True
    nr.font.color.rgb = rgb(WHITE)
    add_text(s, col_x + Inches(0.7), y + Inches(1.1 * row) + Inches(0.08), Inches(4.8), Inches(0.5),
              item, size=15, color=TEXT_DARK, bold=True, anchor=MSO_ANCHOR.MIDDLE)
footer(s, 2)

# =====================================================================
# SLIDE 3 — PROBLEM STATEMENT
# =====================================================================
s = new_slide()
header(s, "The Problem", "Why Bangladeshi Farmers Need This")
cards = [
    (AMBER_BG, AMBER, "\U0001F9EA", "No Accessible Soil-to-Crop Link",
     "A soil test gives N/P/K/pH numbers, but translating that into “which crop will actually do well here” needs agronomic expertise most farmers don't have on hand."),
    (BLUE_BG, BLUE, "\U0001F4B8", "No Transparent Economics",
     "Even an agronomically sound crop can be a financial mistake without an itemized, sourced cost estimate against the farmer's own land size and budget."),
    (PINK_BG, PINK, "\U0001F504", "No Rotation Discipline",
     "Back-to-back repetition of the same crop depletes soil nutrients and builds up pests — yet nothing remembers a land's cropping history when suggesting what's next."),
]
cx = Inches(0.7)
cw = Inches(3.9)
gap = Inches(0.25)
for i, (bg, accent, icon, title, body) in enumerate(cards):
    x = cx + i * (cw + gap)
    card = add_rect(s, x, Inches(1.85), cw, Inches(4.6), fill=CARD_BG, line=CARD_BORDER)
    icon_box = add_rect(s, x + Inches(0.3), Inches(2.15), Inches(0.75), Inches(0.75), fill=bg, rounded=True)
    itf = icon_box.text_frame
    itf.vertical_anchor = MSO_ANCHOR.MIDDLE
    ip = itf.paragraphs[0]
    ip.alignment = PP_ALIGN.CENTER
    ir = ip.add_run()
    ir.text = icon
    ir.font.size = Pt(26)
    add_text(s, x + Inches(0.3), Inches(3.1), cw - Inches(0.6), Inches(0.8), title,
              size=16, color=TEXT_DARK, bold=True)
    add_text(s, x + Inches(0.3), Inches(3.85), cw - Inches(0.6), Inches(2.4), body,
              size=12, color=TEXT_BODY, line_spacing=1.25)
footer(s, 3)

# =====================================================================
# SLIDE 4 — OUR SOLUTION
# =====================================================================
s = new_slide()
header(s, "The Solution", "What AgroPlus Does")
add_text(s, Inches(0.7), Inches(1.7), Inches(11.9), Inches(0.9),
          "A mobile app that turns a short soil sample into a grounded crop recommendation —\nwith real costs, real profit, and an AI assistant that never guesses.",
          size=17, color=TEXT_DARK, bold=True, line_spacing=1.2)
items = [
    ("Soil → Recommendation.  ", "ML-ranked top-3 crops (or a full season plan) from a tiered soil sample and live weather."),
    ("Itemized economics.  ", "Seed, per-nutrient fertilizer, and other costs — sourced from BAMIS, DAM, and BADC, not guessed."),
    ("Rotation-safe by default.  ", "A crop is never suggested a third time in a row on the same land."),
    ("Grounded AI chat.  ", "Every number the assistant states comes from a real tool call against the land's own data."),
    ("Bilingual.  ", "Full English and Bangla localization, with the assistant replying in the farmer's language."),
]
add_bullets(s, Inches(0.9), Inches(2.95), Inches(11.3), Inches(3.8), items, size=15, gap_pt=16)
footer(s, 4)

# =====================================================================
# SLIDE 5 — FEATURE OVERVIEW (full-bleed infographic)
# =====================================================================
s = new_slide(bg=LIGHT_BG)
infographic = HERE / "AgroPlus_Overview_Slide.png"
if infographic.exists():
    s.shapes.add_picture(str(infographic), 0, 0, width=SW, height=SH)
footer(s, 5)

# =====================================================================
# SLIDE 6 — TECH STACK
# =====================================================================
s = new_slide()
header(s, "Under the Hood", "Technology Stack")
stack = [
    (MID, "\U0001F4F1", "Frontend", "Flutter (Dart) — Android & iOS from one codebase, English + Bangla"),
    (AMBER, "⚙️", "Backend", "FastAPI (Python) — REST API, JWT auth, Alembic migrations"),
    (BLUE, "\U0001F5C4️", "Database", "PostgreSQL via SQLAlchemy ORM"),
    (TEAL, "\U0001F9E0", "ML Engine", "XGBoost + Random Forest ensemble, trained on the Kaggle Crop Recommendation dataset"),
    (PINK, "\U0001F916", "AI Assistant", "OpenAI function-calling (gpt-4o-mini) with 6 grounding tools"),
    (MID, "☁️", "Weather", "Open-Meteo — live conditions + 7-day forecast"),
]
cols = 2
cw2 = Inches(5.75)
ch2 = Inches(1.5)
startx = Inches(0.7)
starty = Inches(1.85)
gapx = Inches(0.3)
gapy = Inches(0.22)
for i, (accent, icon, title, desc) in enumerate(stack):
    col = i % cols
    row = i // cols
    x = startx + col * (cw2 + gapx)
    y = starty + row * (ch2 + gapy)
    add_rect(s, x, y, cw2, ch2, fill=CARD_BG, line=CARD_BORDER)
    ic = add_rect(s, x + Inches(0.25), y + Inches(0.37), Inches(0.75), Inches(0.75), fill=LIGHT_BG, rounded=True)
    itf = ic.text_frame
    itf.vertical_anchor = MSO_ANCHOR.MIDDLE
    ip = itf.paragraphs[0]
    ip.alignment = PP_ALIGN.CENTER
    ir = ip.add_run()
    ir.text = icon
    ir.font.size = Pt(24)
    add_text(s, x + Inches(1.2), y + Inches(0.2), cw2 - Inches(1.4), Inches(0.4), title,
              size=14.5, color=accent, bold=True)
    add_text(s, x + Inches(1.2), y + Inches(0.6), cw2 - Inches(1.4), Inches(0.85), desc,
              size=11.5, color=TEXT_BODY, line_spacing=1.15)
footer(s, 6)

# =====================================================================
# SLIDE 7 — SYSTEM ARCHITECTURE
# =====================================================================
s = new_slide()
header(s, "Architecture", "System Design")

def arch_box(x, y, w, h, title, sub, fill, border):
    b = add_rect(s, x, y, w, h, fill=fill, line=border)
    tf = b.text_frame
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    r = p.add_run()
    r.text = title
    r.font.size = Pt(13)
    r.font.bold = True
    r.font.color.rgb = rgb(TEXT_DARK)
    r.font.name = FONT
    if sub:
        p2 = tf.add_paragraph()
        p2.alignment = PP_ALIGN.CENTER
        r2 = p2.add_run()
        r2.text = sub
        r2.font.size = Pt(9.5)
        r2.font.color.rgb = rgb(TEXT_MUTED)
        r2.font.name = FONT
    return b

arch_box(Inches(4.67), Inches(1.75), Inches(4.0), Inches(0.75), "Flutter Mobile Client", "Android / iOS", LIGHT_BG, MID)
add_text(s, Inches(7.0), Inches(2.52), Inches(2.0), Inches(0.3), "REST / JWT", size=9.5, color=TEXT_MUTED, align=PP_ALIGN.CENTER)
arch_box(Inches(2.67), Inches(2.85), Inches(8.0), Inches(0.75), "FastAPI API Layer",
          "auth · farms · recommendations · chat", LIGHT_BG, MID)

services = [
    (Inches(0.7), "ML Recommendation\nEngine", "XGBoost + Random Forest", AMBER_BG, AMBER),
    (Inches(3.68), "Crop Economics\nKnowledge Base", "BAMIS · DAM · BADC", PINK_BG, PINK),
    (Inches(6.66), "Weather Service", "Open-Meteo API", BLUE_BG, BLUE),
    (Inches(9.64), "AI Farm Assistant", "OpenAI function calling", TEAL_BG, TEAL),
]
for x, title, sub, bg, bd in services:
    arch_box(x, Inches(4.0), Inches(2.95), Inches(1.0), title, sub, bg, bd)

arch_box(Inches(2.67), Inches(5.5), Inches(8.0), Inches(0.75), "Persistence", "SQLAlchemy / PostgreSQL", LIGHT_BG, MID)

add_text(s, Inches(0.7), Inches(6.55), Inches(11.9), Inches(0.4),
          "Each service is independently replaceable — swapping the ML model or the chat provider never touches the others.",
          size=11.5, color=TEXT_MUTED, italic=True, align=PP_ALIGN.CENTER)
footer(s, 7)

# =====================================================================
# SLIDE 8 — CORE FLOW: SOIL -> RECOMMENDATION
# =====================================================================
s = new_slide()
header(s, "Core Flow", "From Soil Sample to Recommendation")
steps = [
    ("1", "Create a land", "District, area, soil type, water availability, budget, target season, cropping pattern."),
    ("2", "Sample the soil", "1 / 3 / 5 points depending on area — N, P, K, pH at each."),
    ("3", "Composite reading", "Once every required point is saved, AgroPlus averages them automatically."),
    ("4", "ML scoring", "XGBoost + Random Forest score every supported crop against soil + live weather."),
    ("5", "Rotation filter", "Any crop grown twice in a row on this land is excluded before ranking."),
    ("6", "Result", "Single mode: top-3 ranked. Double/Triple mode: a season-sequenced plan."),
]
y0 = Inches(1.9)
for i, (num, title, desc) in enumerate(steps):
    y = y0 + Inches(0.82) * i
    circ = add_rect(s, Inches(0.8), y, Inches(0.55), Inches(0.55), fill=MID, rounded=True)
    try:
        circ.adjustments[0] = 0.5
    except Exception:
        pass
    ctf = circ.text_frame
    ctf.vertical_anchor = MSO_ANCHOR.MIDDLE
    cp = ctf.paragraphs[0]
    cp.alignment = PP_ALIGN.CENTER
    cr = cp.add_run()
    cr.text = num
    cr.font.size = Pt(16)
    cr.font.bold = True
    cr.font.color.rgb = rgb(WHITE)
    if i < len(steps) - 1:
        add_rect(s, Inches(1.045), y + Inches(0.55), Pt(2), Inches(0.27), fill=CARD_BORDER, rounded=False)
    add_text(s, Inches(1.6), y - Inches(0.02), Inches(3.0), Inches(0.5), title, size=14.5, color=TEXT_DARK, bold=True, anchor=MSO_ANCHOR.MIDDLE)
    add_text(s, Inches(4.5), y - Inches(0.02), Inches(7.3), Inches(0.65), desc, size=12, color=TEXT_BODY, anchor=MSO_ANCHOR.MIDDLE, line_spacing=1.1)
footer(s, 8)

# =====================================================================
# SLIDE 9 — FEATURE: PROFIT ENGINE  (+ screenshot)
# =====================================================================
s = new_slide()
header(s, "Feature Deep-Dive", "Itemized Harvest Economics")
items = [
    ("Seed cost  ", "BADC/DAM seed price × BAMIS recommended seeding rate."),
    ("Fertilizer cost  ", "BAMIS's per-crop recipe (Urea, TSP, MoP, Gypsum…) priced against real DAM market rates, itemized per nutrient."),
    ("Other costs  ", "Labor, irrigation, land prep — the remainder of BAMIS's bundled total after seed + fertilizer."),
    ("Always reconciles  ", "seed + fertilizer + other = total cost, exactly, for every crop."),
    ("Profit estimate  ", "Gross revenue − total cost = net profit, plus a warning if cost exceeds the farmer's budget."),
]
add_bullets(s, Inches(0.7), Inches(1.85), Inches(6.0), Inches(4.8), items, size=13, gap_pt=14)
add_screenshot(s, IMAGES / "08_crop_detail.png", Inches(9.3), Inches(1.55), Inches(5.55))
footer(s, 9)

# =====================================================================
# SLIDE 10 — FEATURE: MULTI-CROPPING & ROTATION  (+ screenshot)
# =====================================================================
s = new_slide()
header(s, "Feature Deep-Dive", "Multi-Cropping & the Rotation Rule")
items = [
    ("Single / Double / Triple  ", "Chosen per land — one crop at a time, or a season-sequenced plan across Rabi / Aus / Aman."),
    ("Season classification  ", "BAMIS's cultivation-season text is classified into Rabi/Aus/Aman once, at data-seeding time."),
    ("The rotation rule  ", "A crop can't be picked if it would be grown a 3rd time in a row — counting the land's recorded history plus the plan being built."),
    ("Automatic substitution  ", "If a season's top pick is blocked, the next-best rotation-safe crop steps in, with a human-readable note explaining why."),
    ("Mango is excluded  ", "A perennial tree crop doesn't fit a within-year seasonal rotation — it stays single-cropping only."),
]
add_bullets(s, Inches(0.7), Inches(1.85), Inches(6.0), Inches(4.8), items, size=13, gap_pt=14)
add_screenshot(s, IMAGES / "07_cropping_plan.png", Inches(9.55), Inches(1.55), Inches(5.55))
footer(s, 10)

# =====================================================================
# SLIDE 11 — FEATURE: AI FARM ASSISTANT  (+ screenshot)
# =====================================================================
s = new_slide()
header(s, "Feature Deep-Dive", "AI Farm Assistant")
items = [
    ("Grounded, not generative  ", "Every number the assistant states comes from a real tool call against the land's own data — never the model's general knowledge."),
    ("Six grounding tools  ", "Soil reading, live weather, 7-day forecast, current recommendation, crop detail, other crop options, and “why this crop?” explanation."),
    ("Honest about gaps  ", "If a soil reading doesn't exist yet, the assistant says so — it never fabricates a plausible-looking answer."),
    ("Persistent per land  ", "One ongoing conversation per land, restored automatically; a “new conversation” action clears it."),
    ("Replies in-language  ", "English question in, Bangla answer out — matching however the farmer writes."),
]
add_bullets(s, Inches(0.7), Inches(1.85), Inches(6.0), Inches(4.8), items, size=13, gap_pt=14)
add_screenshot(s, IMAGES / "09_chat.png", Inches(9.55), Inches(1.4), Inches(5.75))
footer(s, 11)

# =====================================================================
# SLIDE 12 — WEATHER, BUDGET, LOCALIZATION  (+ screenshot)
# =====================================================================
s = new_slide()
header(s, "Feature Deep-Dive", "Weather, Budget Awareness & Localization")
items = [
    ("Live conditions  ", "Current temperature, humidity, and rainfall for the land's district, refreshable on demand."),
    ("7-day forecast  ", "Daily high/low temperature and precipitation, so timing decisions aren't based on a single snapshot."),
    ("Budget-aware warnings  ", "Any crop whose estimated cost exceeds the farmer's stated budget is flagged — on both the list and the detail screen."),
    ("Full Bangla localization  ", "Every screen, every label, every chat reply — switchable at any time, persisted across restarts."),
]
add_bullets(s, Inches(0.7), Inches(1.85), Inches(6.0), Inches(4.5), items, size=13, gap_pt=16)
add_screenshot(s, IMAGES / "10_bangla_dashboard.png", Inches(9.75), Inches(1.4), Inches(5.75))
footer(s, 12)

# =====================================================================
# SLIDE 13 — DATA MODEL AT A GLANCE
# =====================================================================
s = new_slide()
header(s, "Under the Hood", "Data Model at a Glance")
entities = [
    ("Farmer", "Account, credentials"),
    ("District", "64 districts, seeded with coordinates"),
    ("Farm (Land)", "Profile, budget, cropping pattern, rotation history"),
    ("Recommendation", "One per completed soil reading"),
    ("SamplePoint", "N/P/K/pH per sampling point"),
    ("RecommendationCrop", "Ranked crops or a season plan"),
    ("CropEconomics", "Government-sourced yield/price/cost reference data"),
    ("ChatMessage", "Persistent per-land conversation"),
]
cols = 2
cw3 = Inches(5.75)
ch3 = Inches(1.08)
startx = Inches(0.7)
starty = Inches(1.85)
for i, (name, desc) in enumerate(entities):
    col = i % cols
    row = i // cols
    x = startx + col * (cw3 + Inches(0.3))
    y = starty + row * (ch3 + Inches(0.15))
    add_rect(s, x, y, cw3, ch3, fill=CARD_BG, line=CARD_BORDER)
    add_text(s, x + Inches(0.25), y + Inches(0.14), cw3 - Inches(0.5), Inches(0.35), name,
              size=14, color=MID, bold=True)
    add_text(s, x + Inches(0.25), y + Inches(0.54), cw3 - Inches(0.5), Inches(0.45), desc,
              size=11, color=TEXT_BODY)
footer(s, 13)

# =====================================================================
# SLIDE 14 — TESTING & VERIFICATION
# =====================================================================
s = new_slide()
header(s, "Quality", "Testing & Verification")
items = [
    ("Scripted API testing  ", "Every endpoint exercised directly with Python HTTP scripts — happy paths, ownership checks, validation errors."),
    ("Real on-device verification  ", "Every feature walked through live on an Android emulator, not just asserted from backend responses."),
    ("Invariant checks  ", "seed + fertilizer + other = total cost, verified numerically after every pipeline change."),
    ("Rotation-rule testing  ", "Verified a 3rd-in-a-row crop is actually excluded, with the right substitution and note."),
    ("Regression discipline  ", "Backend restarted and re-verified after every schema or logic change throughout development."),
]
add_bullets(s, Inches(0.9), Inches(1.95), Inches(11.3), Inches(4.5), items, size=14.5, gap_pt=18)
footer(s, 14)

# =====================================================================
# SLIDE 15 — LIMITATIONS & FUTURE WORK
# =====================================================================
s = new_slide()
header(s, "Looking Ahead", "Known Limitations & Future Work")
rows = [
    ("Crop coverage", "Only 8 of 22 ML-recognized crops have sourced economics data."),
    ("Season climate data", "Multi-cropping scores every season against the same current weather snapshot."),
    ("Automated tests", "No unit/integration suite yet — testing has been manual and scripted."),
    ("Production deployment", "Runs on a local dev server; no hosting or CI/CD set up yet."),
    ("iOS verification", "Built and tested on Android only so far."),
]
ty = Inches(1.9)
for i, (area, note) in enumerate(rows):
    y = ty + Inches(0.95) * i
    add_rect(s, Inches(0.7), y, Inches(3.0), Inches(0.75), fill=MID, rounded=True)
    add_text(s, Inches(0.9), y, Inches(2.6), Inches(0.75), area, size=13, color=WHITE, bold=True, anchor=MSO_ANCHOR.MIDDLE)
    add_rect(s, Inches(3.85), y, Inches(8.78), Inches(0.75), fill=CARD_BG, line=CARD_BORDER)
    add_text(s, Inches(4.1), y, Inches(8.3), Inches(0.75), note, size=12, color=TEXT_BODY, anchor=MSO_ANCHOR.MIDDLE)
footer(s, 15)

# =====================================================================
# SLIDE 16 — THANK YOU
# =====================================================================
s = new_slide(bg=DARK)
leaf2 = add_rect(s, Inches(5.73), Inches(1.6), Inches(1.0), Inches(1.0), fill=MID, rounded=True)
try:
    leaf2.adjustments[0] = 0.28
except Exception:
    pass
tf2 = leaf2.text_frame
tf2.vertical_anchor = MSO_ANCHOR.MIDDLE
p2 = tf2.paragraphs[0]
p2.alignment = PP_ALIGN.CENTER
r2 = p2.add_run()
r2.text = "\U0001F331"
r2.font.size = Pt(34)

add_text(s, Inches(1.0), Inches(2.9), Inches(11.33), Inches(1.0), "Thank You",
          size=48, color=WHITE, bold=True, align=PP_ALIGN.CENTER)
add_text(s, Inches(1.5), Inches(3.9), Inches(10.33), Inches(0.5), "Questions & Discussion",
          size=18, color="BFE8CC", align=PP_ALIGN.CENTER, italic=True)
add_text(s, Inches(1.5), Inches(5.3), Inches(10.33), Inches(0.4), "AgroPlus — Md. Tuuhidur Rahman",
          size=13, color="EEF7F0", align=PP_ALIGN.CENTER)
add_text(s, Inches(1.5), Inches(5.68), Inches(10.33), Inches(0.4), "SE 801 · Software Project Lab–III",
          size=12, color="A9D6B6", align=PP_ALIGN.CENTER)

prs.save(str(OUT))
print(f"Saved {OUT} ({OUT.stat().st_size} bytes), {len(prs.slides)} slides")
