"""Import source art from assets/ into the game folder art/.

- checks the naming rule  <CODE>__<kind>[__<state>...]  (CODE upper-case, the rest lower-case)
- prefers the PNG original, encodes WEBP (quality 88), limits the longest side
- slices the resource icon sheet into one icon per resource
- skips files whose output is newer than the source (use --force to redo all)

Run from the project root:  python tools/import_art.py [--force]
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets"
DST = ROOT / "art"

FOLDERS = {"districts": "city/districts", "map": "city/map", "ui": "ui"}
NAME_RE = re.compile(r"^[A-Z0-9_]+(__[a-z0-9_]+)+$")
MAX_SIDE = 1672
QUALITY = 88
# Resource sheet: icons left to right, in this order (see GDD 6.1).
RESOURCE_SHEET = "RESOURCES__six_icons"
RESOURCE_IDS = ["gears", "scrap", "electronics", "ichor", "trophy", "money"]


def sources() -> dict[str, Path]:
    """One source per stem: PNG wins over WEBP."""
    found: dict[str, Path] = {}
    for path in sorted(SRC.rglob("*")):
        if path.suffix.lower() not in (".png", ".webp"):
            continue
        key = str(path.relative_to(SRC).with_suffix(""))
        if key not in found or path.suffix.lower() == ".png":
            found[key] = path
    return found


def save_webp(img: Image.Image, out: Path) -> None:
    if max(img.size) > MAX_SIDE:
        img.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "WEBP", quality=QUALITY, method=6)


def _label(mask, seeds_mask):
    """Label connected parts of seeds_mask, then grow labels over mask (multi-source BFS)."""
    from collections import deque

    import numpy as np

    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes: list[int] = [0]
    for y0, x0 in zip(*np.nonzero(seeds_mask)):
        if labels[y0, x0]:
            continue
        lab = len(sizes)
        sizes.append(0)
        labels[y0, x0] = lab
        queue = deque([(y0, x0)])
        while queue:
            y, x = queue.popleft()
            sizes[lab] += 1
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and seeds_mask[ny, nx] and not labels[ny, nx]:
                    labels[ny, nx] = lab
                    queue.append((ny, nx))
    queue = deque(zip(*np.nonzero(labels)))
    while queue:
        y, x = queue.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not labels[ny, nx]:
                labels[ny, nx] = labels[y, x]
                queue.append((ny, nx))
    return labels, sizes


def slice_sheet(img: Image.Image, count: int) -> list[Image.Image]:
    """Split a sheet of (possibly touching) icons into the `count` biggest shapes, left to right."""
    import numpy as np

    scale = 3
    small = img.resize((img.width // scale, img.height // scale), Image.NEAREST)
    alpha = np.array(small.getchannel("A"))
    # Opaque cores separate icons that touch through soft edges.
    labels, sizes = _label(alpha > 16, alpha > 250)
    biggest = sorted(range(1, len(sizes)), key=lambda k: sizes[k], reverse=True)[:count]
    biggest.sort(key=lambda k: np.nonzero(labels == k)[1].mean())
    full = np.array(Image.fromarray(labels.astype(np.int32)).resize(img.size, Image.NEAREST))
    rgba = np.array(img)
    icons = []
    for k in biggest:
        part = rgba.copy()
        part[..., 3] = np.where(full == k, part[..., 3], 0)
        icon = Image.fromarray(part)
        mask = icon.getchannel("A").point(lambda a: 255 if a > 48 else 0)
        icons.append(icon.crop(mask.getbbox()))
    return icons


def main(force: bool) -> int:
    errors: list[str] = []
    written = skipped = 0
    for key, src in sources().items():
        folder, _, stem = key.replace("\\", "/").partition("/")
        if folder not in FOLDERS:
            errors.append(f"{src.relative_to(ROOT)}: unknown folder '{folder}' (expected {', '.join(FOLDERS)})")
            continue
        if not NAME_RE.match(stem):
            errors.append(f"{src.relative_to(ROOT)}: bad name, expected <CODE>__<kind>__<state>")
            continue
        if stem == RESOURCE_SHEET:
            img = Image.open(src).convert("RGBA")
            for rid, icon in zip(RESOURCE_IDS, slice_sheet(img, len(RESOURCE_IDS))):
                save_webp(icon, DST / "ui/icons" / f"RESOURCE__{rid}.webp")
                written += 1
            continue
        out = DST / FOLDERS[folder] / f"{stem}.webp"
        if not force and out.exists() and out.stat().st_mtime >= src.stat().st_mtime:
            skipped += 1
            continue
        img = Image.open(src)
        save_webp(img.convert("RGBA" if img.mode in ("RGBA", "LA", "P") else "RGB"), out)
        written += 1
    for e in errors:
        print("ERROR", e)
    print(f"written {written}, up to date {skipped}, errors {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main("--force" in sys.argv))
