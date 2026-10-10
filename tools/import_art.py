"""Import source art from assets/ into the game folder art/.

- checks the naming rule  <CODE>__<kind>[__<state>...]  (CODE upper-case, the rest lower-case)
- prefers the PNG original, encodes WEBP (quality 88), limits the longest side
- cuts icon sheets assets/icons/<SET>__sheet.png (one image per set, a grid of icons) into one file per icon;
  grid size and order come from data/ui/icons.json
- single icons assets/icons/<SET>__<id>.png are centred on a transparent square of ICON_SIDE px
- assets/png/<folder>/ is read like assets/<folder>/ (the owner's PNG drop folder)
- UI pieces drawn on flat magenta (all four corners #FF00FF) get the magenta keyed out and empty margins trimmed
- textures assets/ui/TEX__*.png are made seamless (edges cross-faded with the image shifted by half)
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
# Not imported file by file: owner's style references; district map pieces (stitched below, GDD 20.8).
SKIP_FOLDERS = {"refs", "district_maps"}
NAME_RE = re.compile(r"^[A-Z0-9_]+(__[a-z0-9_]+)+$")
MAX_SIDE = 1672
# Smaller caps for art shown small on screen (card art window ~176x98 px, crisp at 2x).
MAX_SIDE_BY_PREFIX = {"CARD__art__": 768}
QUALITY = 88
# Sheets made before the naming rule: stem -> (set, (cols, rows)).
LEGACY_SHEETS = {"RESOURCES__six_icons": ("RESOURCE", (6, 1))}
CELL = 256
ICON_SIDE = 256
PNG_DROP = "png/"  # assets/png/<folder>/... is the same as assets/<folder>/...
MIN_PIECE = 40  # smallest loose piece (in 1/3-scale pixels) that still belongs to an icon


def icon_sets() -> dict[str, tuple[list[str], tuple[int, int]]]:
    """Icon set code -> (icon ids in reading order, (cols, rows)) from data/ui/icons.json."""
    import json

    sets = json.loads((ROOT / "data/ui/icons.json").read_text(encoding="utf-8"))
    return {s["set"]: ([i["id"] for i in s["icons"]], (s["grid"][0], s["grid"][1])) for s in sets}


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
        key = path.relative_to(SRC).with_suffix("").as_posix().removeprefix(PNG_DROP)
        if key not in found or path.suffix.lower() == ".png":
            found[key] = path
    return found


def save_webp(img: Image.Image, out: Path) -> None:
    side = next((v for k, v in MAX_SIDE_BY_PREFIX.items() if out.stem.startswith(k)), MAX_SIDE)
    if max(img.size) > side:
        img.thumbnail((side, side), Image.LANCZOS)
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


def slice_grid(img: Image.Image, cols: int, rows: int, count: int) -> list[Image.Image | None]:
    """Cut a sheet laid out as a cols x rows grid (read left to right, top to bottom).

    Every connected shape goes to the grid slot that holds its centre, so small loose bits
    (drips, sparks) stay with their icon and icons that overflow their slot are not cut.
    Returns one image per slot up to `count`; None where a slot is empty.
    """
    import numpy as np

    scale = 3
    small = img.resize((max(1, img.width // scale), max(1, img.height // scale)), Image.NEAREST)
    alpha = np.array(small.getchannel("A"))
    labels, sizes = _label(alpha > 16, alpha > 250)  # opaque cores keep touching icons apart
    h, w = alpha.shape
    slot_of = np.zeros(len(sizes), dtype=np.int32) - 1
    for k in range(1, len(sizes)):
        if sizes[k] < MIN_PIECE:  # specks of noise, not drips or sparks
            continue
        ys, xs = np.nonzero(labels == k)
        col = min(cols - 1, int(xs.mean() / (w / cols)))
        row = min(rows - 1, int(ys.mean() / (h / rows)))
        slot_of[k] = row * cols + col
    slots = np.array(Image.fromarray(slot_of[labels].astype(np.int32)).resize(img.size, Image.NEAREST))
    rgba = np.array(img)
    icons: list[Image.Image | None] = []
    for slot in range(count):
        part = rgba.copy()
        part[..., 3] = np.where(slots == slot, part[..., 3], 0)
        icon = Image.fromarray(part)
        box = icon.getchannel("A").point(lambda a: 255 if a > 48 else 0).getbbox()
        icons.append(icon.crop(box) if box else None)
    return icons


def square_icon(img: Image.Image) -> Image.Image:
    """Trim empty borders, then centre on a transparent ICON_SIDE square (icons line up in the UI)."""
    img = img.convert("RGBA")
    box = img.getchannel("A").getbbox()
    if box:
        img = img.crop(box)
    img.thumbnail((ICON_SIDE - 8, ICON_SIDE - 8), Image.LANCZOS)
    out = Image.new("RGBA", (ICON_SIDE, ICON_SIDE), (0, 0, 0, 0))
    out.paste(img, ((ICON_SIDE - img.width) // 2, (ICON_SIDE - img.height) // 2), img)
    return out


def _single_icon(stem: str, icons: dict[str, tuple[list[str], tuple[int, int]]]) -> str | None:
    """'STATUS__bleed' -> problem text or "" if that icon exists in data/ui/icons.json."""
    set_code, _, icon_id = stem.partition("__")
    if set_code not in icons:
        return f"no icon set '{set_code}' in data/ui/icons.json"
    return "" if icon_id in icons[set_code][0] else f"no icon '{icon_id}' in set {set_code}"


def is_magenta(rgb: tuple) -> bool:
    return rgb[0] > 200 and rgb[2] > 200 and rgb[1] < 90


def key_magenta(img: Image.Image) -> Image.Image:
    """If the four corners are magenta: make magenta transparent (soft edge, no pink fringe) and trim margins."""
    img = img.convert("RGBA")
    w, h = img.size
    corners = [img.getpixel(c) for c in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    if all(c[3] < 8 for c in corners):  # already transparent: only trim the (nearly) empty margins
        box = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        return img.crop(box) if box else img
    if not all(is_magenta(c[:3]) for c in corners):
        return img
    px = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            m = min(r, b) - g  # how magenta the pixel is: 0 for neutral colours, ~255 for pure magenta
            if m > 20:  # despill down to a faint tint; the stronger the magenta, the more transparent
                k = min(1.0, max(0.0, (m - 60) / 120))
                px[x, y] = (r - (m - 20), g, b - (m - 20), int(a * (1 - k)))
    box = img.getchannel("A").getbbox()
    return img.crop(box) if box else img


def make_tileable(img: Image.Image, band: float = 0.25) -> Image.Image:
    """Seamless texture: near the edges show the image shifted by half (its edges then meet the opposite ones),
    cross-faded into the original over `band` of the half-size; the shifted copy's own seam stays hidden."""
    # Textures are opaque: the output is RGB (alpha would be dropped).
    import numpy as np
    a = np.asarray(img.convert("RGB"), np.float32)
    h, w = a.shape[:2]
    shifted = np.roll(a, (h // 2, w // 2), axis=(0, 1))
    tent_x = 1 - np.abs(np.linspace(-1, 1, w, dtype=np.float32))
    tent_y = 1 - np.abs(np.linspace(-1, 1, h, dtype=np.float32))
    t = np.clip(np.minimum.outer(tent_y, tent_x) / band, 0, 1)
    k = (t * t * (3 - 2 * t))[..., None]  # smoothstep: 0 on the edges, 1 inside
    return Image.fromarray((a * k + shifted * (1 - k)).clip(0, 255).astype(np.uint8))


def _sheet_set(stem: str) -> str | None:
    """'STATUS__sheet' -> 'STATUS'."""
    parts = stem.split("__")
    return parts[0] if len(parts) == 2 and parts[1] == "sheet" else None


def main(force: bool) -> int:
    errors: list[str] = []
    written = skipped = 0
    shapes = module_shapes()
    icons = icon_sets()
    for key, src in sources().items():
        folder, _, stem = key.partition("/")
        if folder in SKIP_FOLDERS:
            continue
        if folder not in FOLDERS:
            errors.append(f"{src.relative_to(ROOT)}: unknown folder '{folder}' (expected {', '.join(FOLDERS)})")
            continue
        if not NAME_RE.match(stem):
            errors.append(f"{src.relative_to(ROOT)}: bad name, expected <CODE>__<kind>__<state>")
            continue
        legacy = LEGACY_SHEETS.get(stem)
        set_code = legacy[0] if legacy else _sheet_set(stem) if folder == "icons" else None
        if set_code is not None:
            if set_code not in icons:
                errors.append(f"{src.relative_to(ROOT)}: no icon set '{set_code}' in data/ui/icons.json")
                continue
            ids, grid = icons[set_code]
            cols, rows = legacy[1] if legacy else grid
            for icon_id, icon in zip(ids, slice_grid(Image.open(src).convert("RGBA"), cols, rows, len(ids))):
                if icon is None:
                    errors.append(f"{src.relative_to(ROOT)}: no icon found for '{icon_id}' (grid {cols}x{rows})")
                    continue
                save_webp(icon, DST / "ui/icons" / f"{set_code}__{icon_id}.webp")
                written += 1
            continue
        out = DST / FOLDERS[folder] / f"{stem}.webp"
        if not force and out.exists() and out.stat().st_mtime >= src.stat().st_mtime:
            skipped += 1
            continue
        img = Image.open(src)
        if folder == "icons":
            problem = _single_icon(stem, icons)
            if problem:
                errors.append(f"{src.relative_to(ROOT)}: {problem}")
                continue
            img = square_icon(img)
        if folder == "ui":
            img = make_tileable(img) if stem.startswith("TEX__") else key_magenta(img)
        if folder == "modules":
            code = stem.split("__")[0]
            if code not in shapes:
                errors.append(f"{src.relative_to(ROOT)}: no module '{code.lower()}' in data/gear/modules.json")
                continue
            img = fit_to_shape(img, shapes[code])
        save_webp(img.convert("RGBA" if img.mode in ("RGBA", "LA", "P") else "RGB"), out)
        written += 1
    import district_detail_tiles  # the playable district map: overview + painted detail pieces
    if force or district_detail_tiles.needs_stitch():
        used = district_detail_tiles.stitch()
        print(f"district map GREY: {len(used)} detail pieces on the scaled overview")
    for e in errors:
        print("ERROR", e)
    print(f"written {written}, up to date {skipped}, errors {len(errors)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main("--force" in sys.argv))
