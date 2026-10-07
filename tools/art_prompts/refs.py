"""Small PNG copies of reference art for the prompt document (docx needs PNG).

Run from the project root:  python tools/art_prompts/refs.py
Writes tools/art_prompts/.cache/*.png (not committed).
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / ".cache"
REFS = {
    "WEAPON__tablet.png": ROOT / "art/ui/WEAPON__tablet.webp",
    "TAVERN__contract_board.png": ROOT / "art/ui/TAVERN__contract_board.webp",
    "CONTRACT__tablet.png": ROOT / "art/ui/CONTRACT__tablet.webp",
    "RESOURCES__six_icons.png": ROOT / "assets/ui/RESOURCES__six_icons.webp",
}

if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for name, src in REFS.items():
        if not src.exists():  # sheet sources are local only: fall back to the sliced icons
            icons = sorted((ROOT / "art/ui/icons").glob("RESOURCE__*.webp"))
            tiles = [Image.open(p).convert("RGBA") for p in icons]
            for t in tiles:
                t.thumbnail((200, 200))
            sheet = Image.new("RGBA", (sum(t.width for t in tiles) + 20 * len(tiles), 220), (0, 0, 0, 0))
            x = 0
            for t in tiles:
                sheet.paste(t, (x, 220 - t.height), t)
                x += t.width + 20
            sheet.save(OUT / name)
            continue
        img = Image.open(src)
        img.thumbnail((1100, 1100))
        img.save(OUT / name)
    print("written", OUT)
