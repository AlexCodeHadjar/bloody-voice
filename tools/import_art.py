"""Import source art from assets/ into the game folder art/.

- checks the naming rule  <CODE>__<kind>[__<state>...]  (CODE upper-case, the rest lower-case)
- prefers the PNG original, encodes WEBP (quality 88), limits the longest side
- slices icon sheets assets/icons/<SET>__sheet__<n>.png into one file per icon (order from data/ui/icons.json)
- fits weapon-module art to its exact cell shape (data/gear/*.json): 256 px per cell, transparent outside
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

FOLDERS = {"districts": "city/districts", "map": "city/map", "ui": "ui", "modules": "gear/modules",
           "monsters": "monsters", "icons": "ui/icons"}
NAME_RE = re.compile(r"^[A-Z0-9_]+(__[a-z0-9_]+)+$")
MAX_SIDE = 1672
QUALITY = 88
ICONS_PER_SHEET = 6
LEGACY_SHEETS = {"RESOURCES__six_icons": ("RESOURCE", 1)}  # first sheet, made before the naming rule


def icon_sets() -> dict[str, list[str]]:
    """Icon set code -> icon ids in sheet order (data/ui/icons.json)."""
    import json

    sets = json.loads((ROOT / "data/ui/icons.json").read_text(encoding="utf-8"))
    return {s["set"]: [i["id"] for i in s["icons"]] for s in sets}
CELL = 256


def module_shapes() -> dict[str, list[list[int]]]:
    """Module id (upper case, as in file names) -> list of [x, y] cells."""
    import json

    shapes = json.loads((ROOT / "data/gear/shapes.json").read_text(encoding="utf-8"))
    modules = json.loads((ROOT / "data/gear/modules.json").read_text(encoding="utf-8"))
    return {m["id"].upper(): shapes[m["shape"]]["cells"] for m in modules}


def fit_to_shape(img: Image.Image, cells: list[list[int]]) -> Image.Image:
    """Cover-scale the art to the shape's bounding box and cut away everything outside its cells."""
    from PIL import ImageDraw, ImageOps

    cols = max(c[0] for c in cells) + 1
    rows = max(c[1] for c in cells) + 1
    size = (cols * CELL, rows * CELL)
    art = ImageOps.fit(img.convert("RGBA"), size, Image.LANCZOS)
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    for x, y in cells:
        d.rounded_rectangle([x * CELL, y * CELL, (x + 1) * CELL - 1, (y + 1) * CELL - 1], radius=CELL // 12, fill=255)
    for x, y in cells:  # merge neighbouring cells so the shape has no seams
        for dx, dy in ((1, 0), (0, 1)):
            if [x + dx, y + dy] in cells:
                d.rectangle([x * CELL + CELL // 2, y * CELL + CELL // 2,
                             (x + dx) * CELL + CELL // 2, (y + dy) * CELL + CELL // 2], fill=255)
    alpha = Image.composite(art.getchannel("A"), Image.new("L", size, 0), mask)
    art.putalpha(alpha)
    return art


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


def _sheet_key(stem: str) -> tuple[str, int] | None:
    """'STATUS__sheet__1' -> ('STATUS', 1)."""
    parts = stem.split("__")
    if len(parts) == 3 and parts[1] == "sheet" and parts[2].isdigit():
        return parts[0], int(parts[2])
    return None


def main(force: bool) -> int:
    errors: list[str] = []
    written = skipped = 0
    shapes = module_shapes()
    icons = icon_sets()
    for key, src in sources().items():
        folder, _, stem = key.replace("\\", "/").partition("/")
        if folder not in FOLDERS:
            errors.append(f"{src.relative_to(ROOT)}: unknown folder '{folder}' (expected {', '.join(FOLDERS)})")
            continue
        if not NAME_RE.match(stem):
            errors.append(f"{src.relative_to(ROOT)}: bad name, expected <CODE>__<kind>__<state>")
            continue
        sheet = (LEGACY_SHEETS.get(stem) or _sheet_key(stem)) if folder in ("icons", "ui") else None
        if sheet is not None:
            set_code, index = sheet
            if set_code not in icons:
                errors.append(f"{src.relative_to(ROOT)}: no icon set '{set_code}' in data/ui/icons.json")
                continue
            ids = icons[set_code][(index - 1) * ICONS_PER_SHEET:index * ICONS_PER_SHEET]
            for icon_id, icon in zip(ids, slice_sheet(Image.open(src).convert("RGBA"), len(ids))):
                save_webp(icon, DST / "ui/icons" / f"{set_code}__{icon_id}.webp")
                written += 1
            continue
        out = DST / FOLDERS[folder] / f"{stem}.webp"
        if not force and out.exists() and out.stat().st_mtime >= src.stat().st_mtime:
            skipped += 1
            continue
        img = Image.open(src)
        if folder == "modules":
            code = stem.split("__")[0]
            if code not in shapes:
                errors.append(f"{src.relative_to(ROOT)}: no module '{code.lower()}' in data/gear/modules.json")
                continue
            img = fit_to_shape(img, shapes[code])
        save_webp(img.convert("RGBA" if img.mode in ("RGBA", "LA", "P") else "RGB"), out)
        written += 1
    for e in errors:
        print("ERROR", e)
    print(f"written {written}, up to date {skipped}, errors {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main("--force" in sys.argv))
