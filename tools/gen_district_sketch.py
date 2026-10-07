"""Bloody Voice - close-up district map sketch (GDD 20). First district: Grey Chapels (GREY).

From ONE layout (below) it writes, into docs/assets/districts/GREY/:
  location.png        the district on the city map; every other district darkened (locked at the start)
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

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from district_layout_grey import (  # noqa: E402  (the layout lives next to this tool)
    CONTOUR, HOME_NODE, LANDMARK_NODE, LANDMARKS, NEIGHBOURS, NODES, STREETS, ZONE_LABELS, ZONES)

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "assets" / "districts" / "GREY"
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
    img = Image.new("RGB", size, LOCKED)
    d = ImageDraw.Draw(img, "RGBA")
    _locked_hatching(d, size)
    if labels:
        for code, en, ru, pos in NEIGHBOURS:
            _label(d, sk(pos), ru, "закрыто · locked", 24, (200, 190, 175))
    _ringwall(d, labels)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon([sk(p) for p in CONTOUR], fill=255)
    inside = Image.new("RGB", size, PARCHMENT)
    img.paste(inside, (0, 0), mask)
    d = ImageDraw.Draw(img, "RGBA")
    for _, en, ru, poly, tint in ZONES:
        d.polygon([sk(p) for p in poly], fill=tint + (70,), outline=tint + (200,))
    _houses(d, mask)
    for name, ru, nodes, width in STREETS:
        _street(d, [sk(NODES[n]) for n in nodes], width)
    d.line([sk(p) for p in CONTOUR + CONTOUR[:1]], fill=INK, width=8)
    badges = [_landmark(d, i, lm) for i, lm in enumerate(LANDMARKS, 1)]
    if labels:
        _place_labels(d, size, badges)
        _compass(d, size)
    return img


def _locked_hatching(d: ImageDraw.ImageDraw, size: tuple[int, int]) -> None:
    for x in range(-size[1], size[0], 26):
        d.line([(x, 0), (x + size[1], size[1])], fill=(70, 64, 60), width=3)


def _ringwall(d: ImageDraw.ImageDraw, labels: bool) -> None:
    """The city wall and the abyss east of the district (from map_regions.json wall)."""
    wall = json.loads(REGIONS.read_text(encoding="utf-8"))["wall"]
    (cx, cy), (rx, ry), t = wall["center"], wall["radius"], wall["thickness"]
    pts_in, pts_out = [], []
    for i in range(0, 181):
        a = -1.2 + i * (2.4 / 180)  # east half only
        for r_add, pts in ((-t / 2, pts_in), (t / 2, pts_out)):
            px = cx + (rx + r_add) * math.cos(a)
            py = cy + (ry + r_add) * math.sin(a)
            c = ((px - CROP_ORIGIN[0]) * 2, (py - CROP_ORIGIN[1]) * 2)
            pts.append(sk(c))
    d.polygon(pts_in + pts_out[::-1], fill=(95, 88, 80, 255), outline=INK)
    if labels:
        _label(d, sk((790, 235)), "Кольцевая стена", "Ringwall · за ней Бездна", 22, (220, 210, 190))


def _houses(d: ImageDraw.ImageDraw, mask: Image.Image) -> None:
    """Dense small roofs everywhere that is not a street or landmark: shows the scale."""
    rnd = random.Random(7)
    free = mask.copy()
    fd = ImageDraw.Draw(free)
    for _, _, nodes, width in STREETS:
        fd.line([sk(NODES[n]) for n in nodes], fill=0, width=18 + width * 8)
    for _, _, _, _, pos, (w, h), _ in LANDMARKS:
        x, y = sk(pos)
        fd.rectangle([x - w * SCALE * SKETCH_SCALE / 2 - 8, y - h * SCALE * SKETCH_SCALE / 2 - 8,
                      x + w * SCALE * SKETCH_SCALE / 2 + 8, y + h * SCALE * SKETCH_SCALE / 2 + 8], fill=0)
    for _ in range(5200):
        x, y = rnd.uniform(0, mask.width), rnd.uniform(0, mask.height)
        w, h = rnd.uniform(12, 26), rnd.uniform(10, 22)
        if all(free.getpixel((int(min(max(px, 0), mask.width - 1)), int(min(max(py, 0), mask.height - 1)))) > 0
               for px, py in ((x, y), (x + w, y), (x, y + h), (x + w, y + h))):
            shade = rnd.randint(110, 150)
            d.rectangle([x, y, x + w, y + h], fill=(shade, shade - 8, shade - 16, 255), outline=(70, 62, 56))
            fd.rectangle([x - 3, y - 3, x + w + 3, y + h + 3], fill=0)


def _street(d: ImageDraw.ImageDraw, pts: list[tuple[float, float]], width: int) -> None:
    if width == 0:  # rope bridge: dashed
        for a, b in zip(pts, pts[1:]):
            for k in range(0, 20, 2):
                p = (a[0] + (b[0] - a[0]) * k / 20, a[1] + (b[1] - a[1]) * k / 20)
                q = (a[0] + (b[0] - a[0]) * (k + 1) / 20, a[1] + (b[1] - a[1]) * (k + 1) / 20)
                d.line([p, q], fill=(110, 80, 40), width=5)
        return
    w = {1: 12, 2: 20, 3: 30}[width]
    d.line(pts, fill=INK, width=w + 6, joint="curve")
    d.line(pts, fill=(205, 192, 168), width=w, joint="curve")


def _landmark(d: ImageDraw.ImageDraw, number: int, lm: tuple) -> tuple:
    _id, en, ru, _role, pos, (w, h), kind = lm
    x, y = sk(pos)
    hw, hh = w * SCALE * SKETCH_SCALE / 2, h * SCALE * SKETCH_SCALE / 2
    fill = {"chapel": (120, 118, 135), "gate": (80, 70, 60), "home": BRASS, "tavern": (160, 90, 50),
            "shop": (150, 110, 60), "workshop": (120, 100, 70), "graveyard": (95, 100, 85),
            "bridge": (170, 150, 110), "aqueduct": (140, 130, 120)}.get(kind, (130, 120, 105))
    d.rectangle([x - hw, y - hh, x + hw, y + hh], fill=fill + (235,), outline=INK, width=4)
    if kind == "chapel":  # cross-shaped plan
        d.rectangle([x - hw * 1.5, y - hh * 0.25, x + hw * 1.5, y + hh * 0.2], fill=fill + (235,), outline=INK, width=4)
    r = 26
    d.ellipse([x - r, y - r, x + r, y + r], fill=BLOOD if kind == "gate" else INK, outline=PARCHMENT, width=3)
    d.text((x, y), str(number), font=font(26, True), fill=PARCHMENT, anchor="mm")
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
    for text in ("Штриховка — соседние районы, закрыты в начале игры.", "Пунктир — верёвочные мосты по крышам.",
                 "Красный кружок — выход из района (закрыт).", "Улицы: шире = главнее. Герой ходит только по ним."):
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
    out = OUT / "tile_refs"
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
    ImageDraw.Draw(mask).polygon([city(p) for p in CONTOUR], fill=0)
    img = Image.composite(dark, img, mask)
    d = ImageDraw.Draw(img)
    d.line([city(p) for p in CONTOUR + CONTOUR[:1]], fill=BRASS, width=4)
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
        "contour": [wp(p) for p in CONTOUR],
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
    if "--canvas" in sys.argv:
        seam_canvas(sys.argv[sys.argv.index("--canvas") + 1])
        return
    OUT.mkdir(parents=True, exist_ok=True)
    size = (int(WORLD[0] * SKETCH_SCALE), int(WORLD[1] * SKETCH_SCALE))
    plan = draw_plan(size)
    sheet = Image.new("RGB", (size[0] + 900, size[1]), (30, 26, 24))
    sheet.paste(plan, (0, 0))
    sheet.paste(legend(size[1]), (size[0], 0))
    sheet.save(OUT / "sketch.png")
    tiles_overlay(plan).save(OUT / "tiles.png")
    tile_refs(draw_plan(size, labels=False))
    location().save(OUT / "location.png")
    (OUT / "layout.json").write_text(json.dumps(layout_json(), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("written ->", OUT)


if __name__ == "__main__":
    main()
