"""Render data/city/map_regions.json over the city map art to check the traced regions.

Run from the project root:  python tools/check_map_regions.py [out.png]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
COLORS = [(255, 80, 80), (80, 255, 80), (80, 160, 255), (255, 220, 60), (255, 80, 255), (60, 255, 255)]


def main(out: Path) -> None:
    data = json.loads((ROOT / "data/city/map_regions.json").read_text(encoding="utf-8"))
    art_path = ROOT / data["image"].replace("res://", "")
    if not art_path.exists():
        art_path = ROOT / "assets/map" / Path(data["image"]).name
    img = Image.open(art_path).convert("RGBA")
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for i, region in enumerate(data["regions"]):
        col = COLORS[i % len(COLORS)]
        pts = [tuple(p) for p in region["polygon"]]
        draw.polygon(pts, fill=col + (60,), outline=col + (255,), width=3)
        x = sum(p[0] for p in pts) / len(pts)
        y = sum(p[1] for p in pts) / len(pts)
        draw.text((x - 30, y), region["id"], fill=(255, 255, 255, 255))
    Image.alpha_composite(img, layer).convert("RGB").save(out)
    print("written", out)


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "map_regions_check.png")
