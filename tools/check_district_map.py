"""Render a district map's data (data/city/district_maps/<ID>.json) over its art to check the calibration (GDD 20.9 step 6b).

Run from the project root:
  python tools/check_district_map.py GREY [out.png] [x0 y0 x1 y1] [scale]
Draws the contour (magenta), zones (green), streets (cyan; rope bridges orange), nodes with ids (red / yellow) and
landmark circles with their numbers (white). The same picture is in the game: F3 on the district screen (debug builds).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
KIND_COLOURS = {"main": (0, 255, 255), "street": (0, 200, 255), "alley": (0, 140, 255), "rope": (255, 140, 0)}


def render(district: str, out: Path, box: tuple[int, int, int, int] | None, scale: float) -> None:
    d = json.loads((ROOT / "data" / "city" / "district_maps" / f"{district}.json").read_text(encoding="utf-8"))
    art = Image.open(ROOT / d["image"].replace("res://", "")).convert("RGB")
    x0, y0, x1, y1 = box or (0, 0, art.width, art.height)
    im = art.crop((x0, y0, x1, y1)).resize((int((x1 - x0) * scale), int((y1 - y0) * scale)))
    dr = ImageDraw.Draw(im)

    def p(pt: list[float]) -> tuple[float, float]:
        return (pt[0] - x0) * scale, (pt[1] - y0) * scale

    nodes = d["nodes"]
    dr.line([p(q) for q in d["contour"] + d["contour"][:1]], fill=(255, 0, 255), width=2)
    for z in d["zones"]:
        dr.line([p(q) for q in z["polygon"] + z["polygon"][:1]], fill=(120, 255, 120), width=1)
    for s in d["streets"]:
        dr.line([p(nodes[n]) for n in s["nodes"]], fill=KIND_COLOURS.get(s["kind"], (255, 255, 255)), width=3)
    for node_id, pt in nodes.items():
        x, y = p(pt)
        dr.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 0, 0))
        dr.text((x + 5, y - 6), node_id, fill=(255, 255, 0))
    for lm in d["landmarks"]:
        x, y = p(lm["pos"])
        r = lm["radius"] * scale
        dr.ellipse((x - r, y - r, x + r, y + r), outline=(255, 255, 255), width=2)
        dr.text((x - 6, y - 6), str(lm["number"]), fill=(255, 255, 255))
    im.save(out)
    print(out)


def main() -> None:
    args = sys.argv[1:]
    district = args[0] if args else "GREY"
    out = Path(args[1]) if len(args) > 1 else ROOT / f"{district}_calibration.png"
    box = tuple(int(v) for v in args[2:6]) if len(args) >= 6 else None
    scale = float(args[6]) if len(args) > 6 else 0.25
    render(district, out, box, scale)  # type: ignore[arg-type]


if __name__ == "__main__":
    main()
