"""Map-life sheets (docs/art-prompts/map-life-people.md): assets/ui/LIFE__<set>__sheet.png is a 4 x 2 grid of figures;
each slot becomes art/ui/life/LIFE__<set>__<slot>.webp (slots 1..8 in reading order).

Poses of one person share one crop box, so switching poses does not make the figure jump:
  pass_* and groups_* sheets — slot pairs (walking towards / walking away);
  locals_* sheets — slots 1–4 and 5–8 (one local character in four poses);
  other sheets (roles, animals, emotes) — every slot on its own.
Called by tools/import_art.py.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "ui" / "life"
COLS, ROWS = 4, 2
SCALE = 0.5  # a ~340 px figure becomes ~170 px: crisp on the map (~32 px at zoom 1) even at 2x screens
QUALITY = 88


def is_sheet(stem: str) -> bool:
    return stem.startswith("LIFE__") and stem.endswith("__sheet")


def _pose_group(name: str) -> int:
    kind = name.split("__")[1]
    if kind.startswith("locals_"):
        return 4
    return 2 if kind.startswith(("pass_", "groups_")) else 1


def _union(boxes: list[tuple[int, int, int, int]]) -> tuple[int, int, int, int]:
    return min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)


def cut(src: Path, stem: str, force: bool) -> tuple[int, list[str]]:
    """Cut one sheet; returns (sprites written, problems). Skips the sheet when every output is newer."""
    name = stem.removesuffix("__sheet")
    outs = [OUT / f"{name}__{i + 1}.webp" for i in range(COLS * ROWS)]
    if not force and all(o.exists() and o.stat().st_mtime >= src.stat().st_mtime for o in outs):
        return 0, []
    img = Image.open(src).convert("RGBA")
    cw, ch = img.width // COLS, img.height // ROWS
    cells = [img.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch)) for r in range(ROWS) for c in range(COLS)]
    boxes = [cell.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox() for cell in cells]
    problems = [f"{src.name}: slot {i + 1} is empty" for i, b in enumerate(boxes) if b is None]
    OUT.mkdir(parents=True, exist_ok=True)
    step = _pose_group(name)
    written = 0
    for start in range(0, len(cells), step):
        present = [b for b in boxes[start:start + step] if b]
        if not present:
            continue
        box = _union(present)
        for i in range(start, start + step):
            if boxes[i] is None:
                continue
            sprite = cells[i].crop(box)
            size = (max(1, round(sprite.width * SCALE)), max(1, round(sprite.height * SCALE)))
            sprite.resize(size, Image.LANCZOS).save(outs[i], "WEBP", quality=QUALITY, method=6)
            written += 1
    return written, problems
