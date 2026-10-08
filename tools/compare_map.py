"""Side-by-side for checking a generated district map: the plan (left), the generated image (middle), the approved
Broken Hoist and the owner's style references (right column). One image, so a reviewer reads it in one go.

Run from the project root:  python tools/compare_map.py <generated image> [<out.png>]
A detail piece against its reference:  python tools/compare_map.py --piece r2c1 <painted piece>
Default out: the system temp folder, compare_GREY.png. Used by the map-checker agent (.claude/agents/map-checker.md).
"""
from __future__ import annotations

import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
MAP = ROOT / "docs" / "art-prompts" / "grey-chapels-map"
REFS = ROOT / "assets" / "refs"
H = 1400


def _fit(path: Path, height: int) -> Image.Image | None:
    if not path.exists():
        return None
    im = Image.open(path).convert("RGB")
    return im.resize((im.width * height // im.height, height), Image.LANCZOS)


def compare(generated: Path) -> Image.Image:
    plan = _fit(MAP / "for-gpt" / "plan_clean.png", H)
    gen = _fit(generated, H)
    if gen is None:
        raise SystemExit(f"no such image: {generated}")
    side = [_fit(MAP / "examples" / "approved_18_broken_hoist.png", 330)]
    side += [_fit(p, 250) for p in sorted(REFS.glob("STYLE_ref_*.webp"))[:3]]
    side = [s for s in side if s is not None]
    col_w = max((s.width for s in side), default=0)
    out = Image.new("RGB", (plan.width + gen.width + col_w + 40, H + 50), (24, 22, 22))
    d = ImageDraw.Draw(out)
    font = ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", 28)
    x = 0
    for im, title in ((plan, "PLAN"), (gen, "GENERATED")):
        out.paste(im, (x, 50))
        d.text((x + 10, 10), title, font=font, fill=(217, 181, 106))
        x += im.width + 20
    d.text((x, 10), "HOIST 18 / STYLE REFS", font=font, fill=(217, 181, 106))
    y = 50
    for s in side:
        s.thumbnail((col_w, H))
        out.paste(s, (x, y))
        y += s.height + 10
    return out


def compare_piece(tile: str, generated: Path) -> Image.Image:
    """A detail piece: its reference crop (left), the painted piece (middle), both blended 50/50 (right) —
    in the blend any building that moved shows up doubled."""
    ref = Image.open(MAP / "detail" / "refs" / f"GREY_detail_{tile}_ref.jpg").convert("RGB")
    gen = Image.open(generated).convert("RGB").resize(ref.size, Image.LANCZOS)
    w, h = ref.width // 2, ref.height // 2
    out = Image.new("RGB", (w * 3 + 40, h + 50), (24, 22, 22))
    d = ImageDraw.Draw(out)
    font = ImageFont.truetype("C:/Windows/Fonts/georgiab.ttf", 24)
    for i, (im, title) in enumerate(((ref, "REFERENCE"), (gen, "PAINTED"), (Image.blend(ref, gen, 0.5), "BLEND 50/50"))):
        out.paste(im.resize((w, h), Image.LANCZOS), (i * (w + 20), 50))
        d.text((i * (w + 20) + 10, 12), f"{title} {tile}", font=font, fill=(217, 181, 106))
    return out


def main() -> None:
    if "--piece" in sys.argv:  # python tools/compare_map.py --piece r2c1 <painted piece>
        i = sys.argv.index("--piece")
        out = Path(tempfile.gettempdir()) / f"compare_piece_{sys.argv[i + 1]}.png"
        compare_piece(sys.argv[i + 1], Path(sys.argv[i + 2])).save(out)
        print("written ->", out)
        return
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(tempfile.gettempdir()) / "compare_GREY.png"
    compare(Path(sys.argv[1])).save(out)
    print("written ->", out)


if __name__ == "__main__":
    main()
