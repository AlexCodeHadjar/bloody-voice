"""Detail pass for a district map: the approved overview (ChatGPT, ~1333x2000) becomes the playable map at
3x scale (4000x6000), repainted in 1536x1024 pieces that keep every building where it is.

  python tools/district_detail_tiles.py            -> docs/art-prompts/grey-chapels-map/detail/ (grid + one ref per piece)
  python tools/district_detail_tiles.py --canvas r2c1
                                                   -> assets/district_maps/canvas/GREY_detail_canvas_r2c1.png
  stitch()  (called by tools/import_art.py)        -> art/city/district_maps/GREY__map.webp

Pieces not generated yet are filled from the overview scaled up, so the game map is always complete.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "district_maps"
OVERVIEW = SRC / "GREY__overview.png"
OUT = ROOT / "docs" / "art-prompts" / "grey-chapels-map" / "detail"
MAP_OUT = ROOT / "art" / "city" / "district_maps" / "GREY__map.webp"
OVERVIEW_OUT = ROOT / "art" / "city" / "district_maps" / "GREY__overview.webp"
FACTOR = 3                      # overview px -> map px
TW, TH, OV = 1536, 1024, 128    # piece size (what ChatGPT makes in one go) and the overlap with neighbours
SIZE = (4000, 6000)             # the playable map
COLS = -(-(SIZE[0] - OV) // (TW - OV))
ROWS = -(-(SIZE[1] - OV) // (TH - OV))
FOG = (120, 124, 130)
# Pieces that are (almost) only abyss fog or neighbouring districts: optional, the game darkens them anyway.
OPTIONAL = {"r6c0", "r6c1", "r6c2"}


def origin(r: int, c: int) -> tuple[int, int]:
    """Top-left of piece r/c on the map; the last row/column is pulled back so pieces never leave the map."""
    x = min(c * (TW - OV), SIZE[0] - TW)
    y = min(r * (TH - OV), SIZE[1] - TH)
    return x, y


def base_map() -> Image.Image:
    """The overview scaled up to the map size (the placeholder for pieces not painted yet)."""
    ov = Image.open(OVERVIEW).convert("RGB")
    return ov.resize(SIZE, Image.LANCZOS)


def refs() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "refs").mkdir(exist_ok=True)
    big = base_map()
    for r in range(ROWS):
        for c in range(COLS):
            x, y = origin(r, c)
            big.crop((x, y, x + TW, y + TH)).save(OUT / "refs" / f"GREY_detail_r{r}c{c}_ref.jpg", quality=90)
    grid().save(OUT / "grid.png")


def grid() -> Image.Image:
    ov = Image.open(OVERVIEW).convert("RGB")
    d = ImageDraw.Draw(ov, "RGBA")
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", 26)
    except OSError:
        font = ImageFont.load_default()
    for r in range(ROWS):
        for c in range(COLS):
            x, y = (v / FACTOR for v in origin(r, c))
            tile = f"r{r}c{c}"
            colour = (150, 150, 150, 255) if tile in OPTIONAL else (60, 200, 255, 255)
            d.rectangle([x + 2, y + 2, x + TW / FACTOR - 2, y + TH / FACTOR - 2], outline=colour, width=3)
            d.text((x + 10, y + 8), tile + (" (optional)" if tile in OPTIONAL else ""), font=font, fill=colour,
                   stroke_width=3, stroke_fill=(0, 0, 0))
    return ov


def canvas(tile: str) -> None:
    """A piece-sized canvas: the overlap strips of the finished left and top neighbours pasted in, the rest the
    blurry reference — ChatGPT keeps the strips and repaints the rest in detail."""
    r, c = int(tile[1]), int(tile[3:])
    x, y = origin(r, c)
    img = base_map().crop((x, y, x + TW, y + TH))
    for nr, nc in ((r, c - 1), (r - 1, c)):
        src = SRC / f"GREY__detail__r{nr}c{nc}.png"
        if nr >= 0 and nc >= 0 and src.exists():
            nx, ny = origin(nr, nc)
            piece = Image.open(src).convert("RGB").resize((TW, TH))
            box = (max(x, nx), max(y, ny), min(x + TW, nx + TW), min(y + TH, ny + TH))
            img.paste(piece.crop((box[0] - nx, box[1] - ny, box[2] - nx, box[3] - ny)), (box[0] - x, box[1] - y))
    out = SRC / "canvas"
    out.mkdir(parents=True, exist_ok=True)
    img.save(out / f"GREY_detail_canvas_{tile}.png")
    print("written ->", out / f"GREY_detail_canvas_{tile}.png")


def needs_stitch() -> bool:
    if not OVERVIEW.exists():
        return False
    if not MAP_OUT.exists():
        return True
    newest = max(p.stat().st_mtime for p in [OVERVIEW, *SRC.glob("GREY__detail__r*c*.png")])
    return newest > MAP_OUT.stat().st_mtime


def _ramp(x: int, y: int) -> "np.ndarray":
    """Weight of a piece: 1 inside, a linear ramp across the overlap on every side that has a neighbour piece
    (no ramp at the map edge), so weights of overlapping pieces add up to about 1."""
    wx = np.ones(TW, np.float32)
    wy = np.ones(TH, np.float32)
    ramp_x, ramp_y = np.linspace(0, 1, OV, dtype=np.float32), np.linspace(0, 1, OV, dtype=np.float32)
    if x > 0:
        wx[:OV] = ramp_x
    if x + TW < SIZE[0]:
        wx[-OV:] = ramp_x[::-1]
    if y > 0:
        wy[:OV] = ramp_y
    if y + TH < SIZE[1]:
        wy[-OV:] = ramp_y[::-1]
    return np.outer(wy, wx)


def stitch() -> list[str]:
    """Build the playable map: painted pieces averaged by weight in their overlaps; where the weights add up to
    less than 1 (next to a piece not painted yet) the scaled overview shows through. Returns the pieces used."""
    if not OVERVIEW.exists():
        return []
    MAP_OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.open(OVERVIEW).convert("RGB").save(OVERVIEW_OUT, "WEBP", quality=90)
    base = np.asarray(base_map(), np.float32)
    acc = np.zeros_like(base)
    weight = np.zeros(base.shape[:2], np.float32)
    used = []
    for r in range(ROWS):
        for c in range(COLS):
            src = SRC / f"GREY__detail__r{r}c{c}.png"
            if src.exists():
                x, y = origin(r, c)
                piece = np.asarray(Image.open(src).convert("RGB").resize((TW, TH), Image.LANCZOS), np.float32)
                w = _ramp(x, y)
                acc[y:y + TH, x:x + TW] += piece * w[..., None]
                weight[y:y + TH, x:x + TW] += w
                used.append(f"r{r}c{c}")
    cover = np.minimum(weight, 1.0)[..., None]
    painted = acc / np.maximum(weight, 1e-6)[..., None]
    out = painted * cover + base * (1 - cover)
    Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(MAP_OUT, "WEBP", quality=88)
    return used


if __name__ == "__main__":
    if "--canvas" in sys.argv:
        canvas(sys.argv[sys.argv.index("--canvas") + 1])
    else:
        refs()
        print(f"{ROWS} x {COLS} pieces ->", OUT)
