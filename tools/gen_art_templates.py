"""Templates to attach to ChatGPT image prompts (modules and creatures).

Writes into docs/assets/templates/:
  modules/SHAPE__<id>.png        one template per module shape (256 px cells, transparent outside)
  modules/shapes_overview.png    all shapes on one sheet (for the prompt document)
  monsters/LEAFLET__frame.png    1:1 parchment with the circle the silhouette must fit in
  monsters/COMBAT__frame.png     2:3 transparent frame with safe area and ground line

Shapes come from data/gear/shapes.json, so templates always match the game.
Run from the project root:  python tools/gen_art_templates.py
"""
from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "assets" / "templates"
CELL = 256
FILL = (58, 54, 52, 255)
GRID = (150, 140, 128, 255)
SAFE = (220, 190, 120, 255)
PARCHMENT = (236, 228, 210)
INK = (43, 36, 32)


def load_shapes() -> dict[str, dict]:
    data = json.loads((ROOT / "data/gear/shapes.json").read_text(encoding="utf-8"))
    return {k: v for k, v in data.items() if not k.startswith("_")}


def font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", size)
    except OSError:
        return ImageFont.load_default()


def dashed_rect(d: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color, dash: int = 14, width: int = 3) -> None:
    x0, y0, x1, y1 = box
    for x in range(x0, x1, dash * 2):
        d.line([(x, y0), (min(x + dash, x1), y0)], fill=color, width=width)
        d.line([(x, y1), (min(x + dash, x1), y1)], fill=color, width=width)
    for y in range(y0, y1, dash * 2):
        d.line([(x0, y), (x0, min(y + dash, y1))], fill=color, width=width)
        d.line([(x1, y), (x1, min(y + dash, y1))], fill=color, width=width)


def shape_image(cells: list[list[int]], cell: int = CELL) -> Image.Image:
    cols = max(c[0] for c in cells) + 1
    rows = max(c[1] for c in cells) + 1
    img = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x, y in cells:
        d.rectangle([x * cell, y * cell, (x + 1) * cell - 1, (y + 1) * cell - 1], fill=FILL)
    for x, y in cells:  # cell borders and the safe inset of every cell
        d.rectangle([x * cell, y * cell, (x + 1) * cell - 1, (y + 1) * cell - 1], outline=GRID, width=2)
        m = cell // 16
        dashed_rect(d, (x * cell + m, y * cell + m, (x + 1) * cell - 1 - m, (y + 1) * cell - 1 - m), SAFE, cell // 18, 2)
    return img


def write_modules(shapes: dict[str, dict]) -> None:
    out = OUT / "modules"
    out.mkdir(parents=True, exist_ok=True)
    for sid, shape in shapes.items():
        shape_image(shape["cells"]).save(out / f"SHAPE__{sid}.png")
    # overview sheet
    small = 64
    pad = 40
    tiles = [(sid, shape_image(s["cells"], small)) for sid, s in shapes.items()]
    width = sum(t.width for _, t in tiles) + pad * (len(tiles) + 1)
    sheet = Image.new("RGB", (width, 3 * small + 110), PARCHMENT)
    d = ImageDraw.Draw(sheet)
    x = pad
    for sid, tile in tiles:
        sheet.paste(tile, (x, 40), tile)
        d.text((x, 3 * small + 60), sid, font=font(26), fill=INK)
        x += tile.width + pad
    sheet.save(out / "shapes_overview.png")


def parchment(size: tuple[int, int]) -> Image.Image:
    rnd = random.Random(3)
    img = Image.new("RGB", size, PARCHMENT)
    px = img.load()
    for _ in range(size[0] * size[1] // 30):
        x, y = rnd.randrange(size[0]), rnd.randrange(size[1])
        v = rnd.randint(-18, 6)
        r, g, b = px[x, y]
        px[x, y] = (r + v, g + v, b + v)
    return img


def write_monster_frames() -> None:
    out = OUT / "monsters"
    out.mkdir(parents=True, exist_ok=True)
    leaflet = parchment((1024, 1024))
    d = ImageDraw.Draw(leaflet)
    for a in range(0, 360, 6):  # dashed circle = the round frame of the contract tablet
        d.arc([72, 72, 952, 952], a, a + 3, fill=(160, 120, 70), width=4)
    d.line([(212, 900), (812, 900)], fill=(190, 170, 140), width=2)
    leaflet.save(out / "LEAFLET__frame.png")

    combat = Image.new("RGBA", (1024, 1536), (0, 0, 0, 0))
    d = ImageDraw.Draw(combat)
    dashed_rect(d, (60, 60, 964, 1476), SAFE, 18, 4)
    d.ellipse([262, 1380, 762, 1456], outline=(120, 110, 100, 255), width=3)  # ground shadow
    combat.save(out / "COMBAT__frame.png")


if __name__ == "__main__":
    write_modules(load_shapes())
    write_monster_frames()
    print("written to", OUT)
