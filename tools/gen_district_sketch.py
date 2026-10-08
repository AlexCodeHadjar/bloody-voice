"""Bloody Voice - close-up district map sketch (GDD 20). First district: Grey Chapels (GREY).

From ONE layout (below) it writes, into docs/art-prompts/grey-chapels-map/ (for-gpt/, for-owner/):
  location.png        the district on the city map; every other district darkened (locked at the start)
  plan_clean.png      the plan with numbers only (no words) - the reference image for ChatGPT
  sections.png        side views: Candle Bridge over the Fog Hollow, aqueduct, Ringwall + Edge Walk, borders
  sections_clean.png  the same side views without words (letters A-D only) - for ChatGPT
  sketch.png          top-down plan: real contour, neighbours darkened, zones, streets, numbered landmarks
  tiles.png           the same plan with the generation grid (3 x 4 tiles, 128 px overlap)
  tile_refs/*.png     one reference per tile for ChatGPT: clean plan crop, numbers only (left) + city map crop (right)
  layout.json         contour, landmarks, street graph and tiles in district-map pixels (for the game)

Coordinates below are "C space": a 2x crop of the city map starting at CROP_ORIGIN (easy to read off
art/city/map/HALLOWDEEP__map__normal.webp). The district map is FRAME_C scaled to WORLD.

Run from the project root:  python tools/gen_district_sketch.py
Seam canvas for one tile (after its left/top neighbours are generated into assets/district_maps/):
    python tools/gen_district_sketch.py --canvas r1c1
"""
from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import district_detail as detail  # noqa: E402
from district_sections import sections  # noqa: E402
from district_layout_grey import (  # noqa: E402  (the layout lives next to this tool)
    AQUEDUCT, BONFIRES, BORDER, BRIDGE, GULLY, CONTOUR, HOME_NODE, LANDMARK_NODE, LANDMARKS, NEIGHBOURS, NODES, STREETS, ZONE_LABELS, ZONES)

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "art-prompts" / "grey-chapels-map"
GPT = OUT / "for-gpt"      # files attached in ChatGPT (no words in them)
OWNER = OUT / "for-owner"  # labelled sketches for the owner
CITY_MAP = ROOT / "art" / "city" / "map" / "HALLOWDEEP__map__normal.webp"
REGIONS = ROOT / "data" / "city" / "map_regions.json"
FONT = "C:/Windows/Fonts/georgia.ttf"
FONT_BOLD = "C:/Windows/Fonts/georgiab.ttf"
FONT_ITALIC = "C:/Windows/Fonts/georgiai.ttf"
TILES_SRC = ROOT / "assets" / "district_maps"

CROP_ORIGIN = (780, 230)          # C space (x, y) -> city map (780 + x/2, 230 + y/2)
TILE, OVERLAP, COLS, ROWS = 1024, 128, 3, 4
STEP = TILE - OVERLAP
WORLD = (COLS * STEP + OVERLAP, ROWS * STEP + OVERLAP)   # 2816 x 3712 px district map
FRAME_C = (100.0, 90.0)           # top-left of the district map in C space
SCALE = WORLD[0] / 768.0          # C px -> district map px
SKETCH_SCALE = 0.5                # sketch.png is half the district map size

INK = (43, 36, 32)
PARCHMENT = (236, 228, 210)
BRASS = (176, 138, 74)
BLOOD = (138, 28, 28)
LOCKED = (52, 48, 46)


def world(p: tuple[float, float]) -> tuple[float, float]:
    """C space -> district map pixels."""
    return ((p[0] - FRAME_C[0]) * SCALE, (p[1] - FRAME_C[1]) * SCALE)


def city(p: tuple[float, float]) -> tuple[float, float]:
    """C space -> city map pixels."""
    return (CROP_ORIGIN[0] + p[0] / 2, CROP_ORIGIN[1] + p[1] / 2)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def sk(p: tuple[float, float]) -> tuple[float, float]:
    """C space -> sketch.png pixels."""
    x, y = world(p)
    return (x * SKETCH_SCALE, y * SKETCH_SCALE)


def draw_plan(size: tuple[int, int], labels: bool = True) -> Image.Image:
    """labels=False: numbers only (the reference for ChatGPT must not contain words)."""
    rnd = random.Random(7)
    img = Image.new("RGB", size, LOCKED)
    inner, outer = _wall_lines()
    district = Image.new("L", size, 0)
    ImageDraw.Draw(district).polygon(outline_sk(inner), fill=255)
    beyond = Image.new("L", size, 0)
    ImageDraw.Draw(beyond).polygon(inner + [(size[0] + 400, inner[-1][1]), (size[0] + 400, inner[0][1])], fill=255)
    _neighbours(img, size, district, beyond, rnd)
    img.paste(Image.new("RGB", size, GROUND), (0, 0), district)
    d = ImageDraw.Draw(img, "RGBA")
    for _, _en, _ru, poly, tint in ZONES:
        d.polygon([sk(p) for p in poly], fill=tint + (30,))
    detail.gully(d, [sk(p) for p in GULLY], rnd)
    streets = [[sk(NODES[n]) for n in nodes] for _, _, nodes, _ in STREETS]
    widths = [w for _, _, _, w in STREETS]
    for pts, w in zip(streets, widths):
        detail.street(d, pts, w)
    for a, b, kind, _ru, _en in BORDER:
        if kind != "ringwall":
            detail.border(d, [sk(CONTOUR[i % len(CONTOUR)]) for i in range(a, b + 1)], kind)
    detail.ringwall(d, inner, outer)
    free = _free_mask(district, streets, widths)
    detail.terraces(d, free, streets, widths, rnd)
    detail.yards(d, free, rnd, 9000, streets=streets)
    detail.aqueduct(d, sk(AQUEDUCT[0]), sk(AQUEDUCT[1]))
    detail.bridge(d, sk(NODES[BRIDGE[0]]), sk(NODES[BRIDGE[1]]))
    k = SCALE * SKETCH_SCALE
    for _id, _en, _ru, _role, pos, (w, h), kind in LANDMARKS:
        detail.landmark(d, sk(pos), w * k, h * k, kind, rnd)
    for pts, w in zip(streets, widths):
        detail.lamps(d, pts, w)
    for p in BONFIRES:
        detail.bonfire(d, sk(p))
    badges = [_badge(d, i, lm) for i, lm in enumerate(LANDMARKS, 1)]
    if labels:
        for code, en, ru, pos in NEIGHBOURS:
            _label(d, sk(pos), ru, "закрыто · locked", 24, (220, 210, 195))
        _label(d, sk((790, 235)), "Кольцевая стена", "Ringwall · за ней Бездна", 22, (220, 210, 190))
        _place_labels(d, size, badges)
        _compass(d, size)
    return img


GROUND = (146, 138, 124)
EAST = (7, 12)  # CONTOUR indices of the stretch that is replaced by the Ringwall's inner edge


def outline_sk(inner: list[tuple[float, float]]) -> list[tuple[float, float]]:
    """The district outline in sketch px: CONTOUR, but on the east it runs along the Ringwall itself."""
    top, bottom = sk(CONTOUR[EAST[0]])[1], sk(CONTOUR[EAST[1]])[1]
    wall = [p for p in inner if top <= p[1] <= bottom]
    return [sk(p) for p in CONTOUR[:EAST[0] + 1]] + wall + [sk(p) for p in CONTOUR[EAST[1]:]]


def outline_c() -> list[tuple[float, float]]:
    """The same outline in C space (for layout.json)."""
    k = SCALE * SKETCH_SCALE
    inner = _wall_lines()[0][::3]  # the wall arc is dense; every 3rd point keeps it within ~1 px
    return [(x / k + FRAME_C[0], y / k + FRAME_C[1]) for x, y in outline_sk(inner)]


def check_inside(outline: list[tuple[float, float]], tolerance: float = 12.0) -> None:
    """Every street node and landmark must be inside the outline (gates may sit on it, within tolerance)."""
    points = list(NODES.items()) + [(lm[0], lm[4]) for lm in LANDMARKS]
    bad = [name for name, p in points if not detail.inside_or_near(outline, p, tolerance)]
    if bad:
        raise SystemExit(f"outside the district outline: {', '.join(bad)}")


def _wall_lines() -> tuple[list[tuple[float, float]], list[tuple[float, float]]]:
    """Inner and outer edge of the Ringwall east of the district (from map_regions.json wall), sketch px."""
    wall = json.loads(REGIONS.read_text(encoding="utf-8"))["wall"]
    (cx, cy), (rx, ry), t = wall["center"], wall["radius"], wall["thickness"]
    inner, outer = [], []
    for i in range(0, 181):
        a = -1.2 + i * (2.4 / 180)  # east half only
        for r_add, pts in ((-t / 2, inner), (t / 2, outer)):
            px = cx + (rx + r_add) * math.cos(a)
            py = cy + (ry + r_add) * math.sin(a)
            pts.append(sk(((px - CROP_ORIGIN[0]) * 2, (py - CROP_ORIGIN[1]) * 2)))
    return inner, outer


def _neighbours(img: Image.Image, size: tuple[int, int], district: Image.Image, beyond: Image.Image,
                rnd: random.Random) -> None:
    """Neighbouring districts: their own houses, stopping one street short of the border, then hatched."""
    area = Image.new("L", size, 255)
    area.paste(0, (0, 0), district)
    area.paste(0, (0, 0), beyond)
    gap = area.copy()
    outline = outline_sk(_wall_lines()[0])
    ImageDraw.Draw(gap).line(outline + outline[:1], fill=0, width=46)
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 0, size[0], size[1]], fill=(70, 66, 62))
    detail.yards(d, gap, rnd, 5000, (16, 30))
    hatch = Image.new("RGBA", size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hatch)
    for x in range(-size[1], size[0], 22):
        hd.line([(x, 0), (x + size[1], size[1])], fill=(20, 18, 18, 150), width=3)
    img.paste(Image.new("RGB", size, (20, 18, 18)), (0, 0), Image.eval(area, lambda v: v * 80 // 255))
    img.paste(hatch.convert("RGB"), (0, 0), ImageChops.multiply(hatch.getchannel("A"), area))


def _free_mask(district: Image.Image, streets: list, widths: list[int]) -> Image.Image:
    """Where houses may stand: inside the district, off streets, gully, bridge, aqueduct and landmarks."""
    free = district.copy()
    fd = ImageDraw.Draw(free)
    for pts, w in zip(streets, widths):
        fd.line(pts, fill=0, width={0: 4, 1: 15, 2: 23, 3: 33}[w])
    fd.polygon([sk(p) for p in GULLY], fill=0)
    fd.line([sk(AQUEDUCT[0]), sk(AQUEDUCT[1])], fill=0, width=30)
    fd.line([sk(p) for p in CONTOUR + CONTOUR[:1]], fill=0, width=16)
    fd.line(_wall_lines()[0], fill=0, width=130)  # a street's width along the Ringwall stays open (Edge Walk)
    k = SCALE * SKETCH_SCALE
    for _id, _en, _ru, _role, pos, (w, h), _kind in LANDMARKS:
        x, y = sk(pos)
        fd.rectangle([x - w * k / 2 - 6, y - h * k / 2 - 6, x + w * k / 2 + 6, y + h * k / 2 + 6], fill=0)
    return free


def _badge(d: ImageDraw.ImageDraw, number: int, lm: tuple) -> tuple:
    x, y = sk(lm[4])
    r = 24
    d.ellipse([x - r, y - r, x + r, y + r], fill=BLOOD if lm[6] == "gate" else INK, outline=PARCHMENT, width=3)
    d.text((x, y), str(number), font=font(24, True), fill=PARCHMENT, anchor="mm")
    return (x - r, y - r, x + r, y + r)


def _place_labels(d: ImageDraw.ImageDraw, size: tuple[int, int], badges: list[tuple]) -> None:
    """Zone, landmark and street names, drawn last and on top, each moved until it overlaps nothing placed."""
    taken: list[tuple] = list(badges)
    for zone_id, _en, ru, _poly, _tint in ZONES:
        if zone_id in ZONE_LABELS:
            _put(d, size, taken, [sk(ZONE_LABELS[zone_id])], ru.upper(), font(22, True), (110, 80, 50), plate=True)
    for _id, _en, ru, _role, pos, (w, h), _kind in LANDMARKS:
        x, y = sk(pos)
        hw, hh = max(w * SCALE * SKETCH_SCALE / 2, 26), max(h * SCALE * SKETCH_SCALE / 2, 26)
        tw = d.textlength(ru, font=font(17, True)) / 2
        spots = [(x, y + hh + 14), (x, y - hh - 14), (x + hw + tw + 10, y), (x - hw - tw - 10, y),
                 (x, y + hh + 38), (x, y - hh - 38)]
        _put(d, size, taken, spots, ru, font(17, True), INK)
    for _name, ru, nodes, _width in STREETS:
        pts = [sk(NODES[n]) for n in nodes]
        a, b = max(zip(pts, pts[1:]), key=lambda seg: math.dist(seg[0], seg[1]))
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        _put(d, size, taken, [mid, (mid[0], mid[1] + 22), (mid[0], mid[1] - 22)], ru,
             ImageFont.truetype(FONT_ITALIC, 15), (70, 55, 40), required=False)


def _put(d: ImageDraw.ImageDraw, size: tuple[int, int], taken: list[tuple], spots: list[tuple[float, float]],
         text: str, f: ImageFont.FreeTypeFont, color: tuple, plate: bool = False, required: bool = True) -> None:
    def box_at(p: tuple[float, float]) -> tuple:
        x0, y0, x1, y1 = d.textbbox(p, text, font=f, anchor="mm")
        shift = max(0, 6 - x0) - max(0, x1 - (size[0] - 6))
        return (x0 + shift - 4, y0 - 3, x1 + shift + 4, y1 + 3)

    def free(b: tuple) -> bool:
        return all(b[2] < t[0] or b[0] > t[2] or b[3] < t[1] or b[1] > t[3] for t in taken)

    box = next((box_at(p) for p in spots if free(box_at(p))), None)
    if box is None:
        if not required:
            return
        box = box_at(spots[0])
    if plate:
        d.rectangle(box, fill=(236, 228, 210, 200))
    d.text(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), text, font=f, fill=color, anchor="mm", stroke_width=3,
           stroke_fill=PARCHMENT)
    taken.append(box)


def _label(d: ImageDraw.ImageDraw, at: tuple[float, float], ru: str, en: str, size: int, color: tuple) -> None:
    d.text(at, ru, font=font(size, True), fill=color, anchor="mm", stroke_width=3, stroke_fill=(30, 26, 24))
    d.text((at[0], at[1] + size), en, font=font(int(size * 0.75)), fill=color, anchor="mm")


def _compass(d: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
    x, y = 70, 150
    d.polygon([(x, y - 60), (x - 18, y), (x + 18, y)], fill=INK)
    d.text((x, y - 80), "N / С", font=font(24, True), fill=PARCHMENT, anchor="mm")
    house_px = 35  # a typical house of the district art (~70 px at native size), in sketch px
    d.line([(x + 60, y), (x + 60 + house_px * 4, y)], fill=PARCHMENT, width=6)
    d.text((x + 60, y + 24), "≈ 4 houses / 4 дома", font=font(18), fill=PARCHMENT, anchor="lm")


def legend(height: int) -> Image.Image:
    img = Image.new("RGB", (900, height), (30, 26, 24))
    d = ImageDraw.Draw(img)
    d.text((30, 30), "Серые Часовни — приближенная карта", font=font(34, True), fill=BRASS)
    d.text((30, 78), "Grey Chapels — close-up district map (GDD §20)", font=font(22), fill=PARCHMENT)
    y = 130
    for i, (_id, en, ru, role, *_rest) in enumerate(LANDMARKS, 1):
        d.text((30, y), f"{i:>2}. {ru}", font=font(24, True), fill=PARCHMENT)
        d.text((80, y + 30), f"{en} — {role}", font=font(18), fill=(190, 180, 165))
        y += 66
    y += 10
    for text in ("СТЕНЫ МЕЖДУ РАЙОНАМИ НЕТ: граница — улица (север), трамвайная",
                 "насыпь (запад), ж/д виадук (юг); восток — Кольцевая стена.",
                 "Штриховка — соседние районы (свои дома), закрыты в начале игры.",
                 "Тёмный провал — Туманный лог, на 2 этажа ниже улиц, в тумане.",
                 "Мост Свечей и акведук — см. разрезы в sections.png.",
                 "Жёлтые точки — газовые фонари; оранжевые — костры.",
                 "Коричневая линия с поперечинами — верёвочные мосты по крышам.",
                 "Красный кружок — выход из района (закрыт).",
                 "Улицы: шире = главнее. Герой ходит только по ним."):
        d.text((30, y), text, font=font(20), fill=(200, 190, 175))
        y += 32
    return img


def tiles_overlay(plan: Image.Image) -> Image.Image:
    img = plan.copy()
    d = ImageDraw.Draw(img, "RGBA")
    s = SKETCH_SCALE
    for r in range(ROWS):
        for c in range(COLS):
            x, y = c * STEP * s, r * STEP * s
            d.rectangle([x, y, x + TILE * s, y + TILE * s], outline=(40, 120, 220, 255), width=5)
            d.text((x + 20, y + 16), f"r{r}c{c}", font=font(36, True), fill=(40, 120, 220, 255))
    return img


def tile_refs(plan: Image.Image) -> None:
    """plan: the clean version (numbers only, no words)."""
    city_img = Image.open(CITY_MAP).convert("RGB")
    out = GPT / "tile_refs"
    out.mkdir(parents=True, exist_ok=True)
    for r in range(ROWS):
        for c in range(COLS):
            wx, wy = c * STEP, r * STEP
            left = plan.crop((int(wx * SKETCH_SCALE), int(wy * SKETCH_SCALE),
                              int((wx + TILE) * SKETCH_SCALE), int((wy + TILE) * SKETCH_SCALE))).resize((TILE, TILE))
            x0, y0 = city(((wx / SCALE) + FRAME_C[0], (wy / SCALE) + FRAME_C[1]))
            span = TILE / SCALE / 2
            right = city_img.crop((int(x0), int(y0), int(x0 + span), int(y0 + span))).resize((TILE, TILE), Image.LANCZOS)
            ref = Image.new("RGB", (TILE * 2, TILE))
            ref.paste(left, (0, 0))
            ref.paste(right, (TILE, 0))
            ref.save(out / f"GREY_tile_r{r}c{c}_ref.png")


def location() -> Image.Image:
    img = Image.open(CITY_MAP).convert("RGB")
    dark = Image.new("RGB", img.size, (12, 10, 10))
    mask = Image.new("L", img.size, 175)
    ImageDraw.Draw(mask).polygon([city(p) for p in outline_c()], fill=0)
    img = Image.composite(dark, img, mask)
    d = ImageDraw.Draw(img)
    d.line([city(p) for p in outline_c() + outline_c()[:1]], fill=BRASS, width=4)
    x0, y0 = city(FRAME_C)
    x1, y1 = city((FRAME_C[0] + WORLD[0] / SCALE, FRAME_C[1] + WORLD[1] / SCALE))
    d.rectangle([x0, y0, x1, y1], outline=(40, 120, 220), width=3)
    d.text((x0 + 8, y0 + 6), "district map frame", font=font(18), fill=(40, 120, 220))
    return img


def layout_json() -> dict:
    def wp(p: tuple[float, float]) -> list[int]:
        return [round(v) for v in world(p)]
    return {
        "_comment": "Generated by tools/gen_district_sketch.py. District map pixels (art 2816x3712).",
        "district": "GREY", "size": list(WORLD), "tile": TILE, "overlap": OVERLAP, "grid": [COLS, ROWS],
        "contour": [wp(p) for p in outline_c()],
        "neighbours": [{"district": c, "label": [wp(pos)[0], wp(pos)[1]]} for c, _, _, pos in NEIGHBOURS],
        "zones": [{"id": z, "name_en": en, "name_ru": ru, "polygon": [wp(p) for p in poly]}
                  for z, en, ru, poly, _ in ZONES],
        "landmarks": [{"id": i, "name_en": en, "name_ru": ru, "role": role, "pos": wp(pos), "node": LANDMARK_NODE[i]}
                      for i, en, ru, role, pos, _, _ in LANDMARKS],
        "nodes": {k: wp(v) for k, v in NODES.items()},
        "streets": [{"name_en": n, "name_ru": ru, "nodes": nodes, "width": w} for n, ru, nodes, w in STREETS],
        "home": HOME_NODE,
    }


def seam_canvas(tile: str) -> None:
    """A 1024 canvas for one tile: the left / top 128 px strips copied from the generated neighbours, the rest
    flat grey. ChatGPT gets it with "keep the strips untouched, paint only the grey part"."""
    r, c = int(tile[1]), int(tile[3])
    canvas = Image.new("RGB", (TILE, TILE), (128, 128, 128))
    for (nr, nc), crop in (((r, c - 1), (STEP, 0, TILE, TILE)), ((r - 1, c), (0, STEP, TILE, TILE))):
        src = TILES_SRC / f"GREY__map__r{nr}c{nc}.png"
        if nr >= 0 and nc >= 0 and src.exists():
            canvas.paste(Image.open(src).convert("RGB").resize((TILE, TILE)).crop(crop), (0, 0))
    out = TILES_SRC / "canvas"
    out.mkdir(parents=True, exist_ok=True)
    canvas.save(out / f"GREY_canvas_{tile}.png")
    print("written ->", out / f"GREY_canvas_{tile}.png")


def main() -> None:
    check_inside(outline_c())
    if "--canvas" in sys.argv:
        seam_canvas(sys.argv[sys.argv.index("--canvas") + 1])
        return
    for folder in (GPT, OWNER):
        folder.mkdir(parents=True, exist_ok=True)
    size = (int(WORLD[0] * SKETCH_SCALE), int(WORLD[1] * SKETCH_SCALE))
    plan = draw_plan(size)
    sheet = Image.new("RGB", (size[0] + 900, size[1]), (30, 26, 24))
    sheet.paste(plan, (0, 0))
    sheet.paste(legend(size[1]), (size[0], 0))
    sheet.save(OWNER / "sketch.png")
    tiles_overlay(plan).save(OWNER / "tiles.png")
    tile_refs(draw_plan(size, labels=False))
    location().save(GPT / "location.png")
    sections(FONT_BOLD, FONT).save(OWNER / "sections.png")
    sections(FONT_BOLD, FONT, clean=True).save(GPT / "sections_clean.png")
    draw_plan(size, labels=False).save(GPT / "plan_clean.png")
    (OUT / "layout.json").write_text(json.dumps(layout_json(), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("written ->", OUT)


if __name__ == "__main__":
    main()
