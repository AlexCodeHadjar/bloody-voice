"""Bloody Voice - city reference sketch generator.

Produces, from ONE layout definition (so they never disagree):
  docs/assets/map/city_sketch.png         top-down district sketch with legend
  docs/assets/map/city_cross_section.png  vertical layers of the city
  docs/assets/map/city_grid.txt           ASCII grid of the same layout (for ChatGPT)

Run from the project root:  python tools/gen_city_sketch.py
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "docs" / "assets" / "map"
FONT_DIR = Path("C:/Windows/Fonts")


@dataclass(frozen=True)
class District:
    code: str          # stable id used in data files and prompts
    char: str          # ASCII grid symbol
    name: str
    role: str
    color: tuple[int, int, int]
    label_at: tuple[float, float]  # (compass degrees, normalized radius)


DISTRICTS: dict[str, District] = {d.code: d for d in [
    District("CROWN", "C", "Crown Ward", "administration, nobility", (196, 160, 92), (0, 0.0)),
    District("SILVERHILL", "S", "Silverhill", "cathedral, convent, cemetery", (172, 178, 196), (345, 0.70)),
    District("VIGIL", "V", "Vigil Spire Ward", "knight order HQ", (120, 132, 150), (48, 0.40)),
    District("LUMEN", "L", "Lumen Campus", "Collegium, Great Library, labs", (108, 150, 158), (114, 0.42)),
    District("MARKET", "M", "Rowan Market", "main market, shop", (176, 134, 84), (175, 0.36)),
    District("AVENUES", "A", "The Numbered Avenues", "middle class, largest", (150, 140, 118), (255, 0.74)),
    District("MORRELL", "H", "Morrell Ward", "apothecaries, clinics, morgue", (126, 156, 116), (286, 0.38)),
    District("NORDHAL", "N", "Nordhal Quarter", "hunters, tavern, hero's workshop", (150, 98, 78), (36, 0.62)),
    District("GREY", "G", "Grey Chapels", "slums at platform edge", (110, 108, 104), (85, 0.80)),
    District("DEEPWRIGHT", "D", "Deepwright Lifts", "industry, mine lifts down", (98, 88, 82), (140, 0.74)),
    District("SCARLET", "R", "Scarlet Lantern Row", "red-light, black market", (156, 64, 64), (189, 0.76)),
    District("EXCHANGE", "X", "Rowan Exchange Posts", "3 trading posts at the gates", (204, 178, 112), (0, 0.0)),
    District("WALL", "#", "The Ringwall", "outer bastion, gates", (52, 48, 46), (0, 0.0)),
    District("FOG", "~", "Mistveil (outside)", "fog wasteland, not walkable", (205, 205, 200), (0, 0.0)),
]}

# Exchange posts sit at the three gates and form a triangle around the Crown Ward.
GATES = {"Hawk Gate": 0.0, "Wolf Gate": 120.0, "Bear Gate": 240.0}

# Numbered landmarks: (number, name, compass degrees, normalized radius)
LANDMARKS = [
    (1, "Crown Magistracy citadel", 0, 0.0),
    (2, "The Vigil Spire (300 m tower)", 32, 0.28),
    (3, "Great Library of the Collegium", 95, 0.27),
    (4, "Cathedral of the Pale Vault", 352, 0.36),
    (5, "Convent of St. Aldric", 330, 0.82),
    (6, "Rowan Market - the shop table", 165, 0.30),
    (7, "Tavern 'The Lantern & Hook' (contract board)", 18, 0.82),
    (8, "Hero's workshop-home", 50, 0.84),
    (9, "Deepwright Main Lifts (descent)", 145, 0.86),
    (10, "Morrell Apothecarium & clinic", 258, 0.27),
    (11, "Scarlet Supper auction house", 192, 0.88),
    (12, "The Old Grey Chapel", 80, 0.92),
    (13, "Quiet bookshop, 23rd Avenue (easter egg)", 228, 0.62),
    (14, "Hawk Gate post", 0, 0.90),
    (15, "Wolf Gate post", 120, 0.90),
    (16, "Bear Gate post", 240, 0.90),
]


# ---------------------------------------------------------------- layout ----

def _in_range(a: np.ndarray, lo: float, hi: float) -> np.ndarray:
    """Angle in [lo, hi) with wrap-around (degrees)."""
    a = a % 360.0
    return (a >= lo) & (a < hi) if lo <= hi else (a >= lo) | (a < hi)


def classify(theta: np.ndarray, rn: np.ndarray) -> np.ndarray:
    """Return an array of district codes for compass angle (deg) and normalized radius.

    rn = 1.0 is the inner face of the Ringwall.
    """
    t = np.radians(theta)
    out = np.full(theta.shape, "AVENUES", dtype=object)

    wob = 7 * np.sin(3 * t + rn * 7) + 4 * np.sin(7 * t + 1.3)   # irregular borders
    tw = (theta + wob) % 360.0
    core = 0.20 + 0.03 * np.sin(5 * t) + 0.02 * np.sin(9 * t + 1)
    ring_split = 0.52 + 0.05 * np.sin(4 * t + 0.7) + 0.03 * np.sin(9 * t)

    inner = rn < ring_split
    for code, lo, hi in [("SILVERHILL", 318, 18), ("VIGIL", 18, 68), ("LUMEN", 68, 138),
                         ("MARKET", 138, 212), ("AVENUES", 212, 248), ("MORRELL", 248, 318)]:
        out[inner & _in_range(tw, lo, hi)] = code
    outer = ~inner
    for code, lo, hi in [("SILVERHILL", 322, 6), ("NORDHAL", 6, 62), ("GREY", 62, 108),
                         ("DEEPWRIGHT", 108, 172), ("SCARLET", 172, 206), ("AVENUES", 206, 322)]:
        out[outer & _in_range(tw, lo, hi)] = code

    for gate_deg in GATES.values():
        d = np.abs(((theta - gate_deg + 180) % 360) - 180)
        post = (d < 9 + 2 * np.sin(rn * 30)) & (rn > 0.82) & (rn < 1.0)
        out[post] = "EXCHANGE"

    out[rn < core] = "CROWN"
    out[(rn >= 1.0) & (rn < 1.07)] = "WALL"
    out[rn >= 1.07] = "FOG"
    return out


def polar_grid(w: int, h: int, cx: float, cy: float, radius: float):
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    dx, dy = xs - cx, ys - cy
    theta = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    return theta, np.hypot(dx, dy) / radius


def to_xy(deg: float, rn: float, cx: float, cy: float, radius: float) -> tuple[float, float]:
    t = math.radians(deg)
    return cx + math.sin(t) * rn * radius, cy - math.cos(t) * rn * radius


# --------------------------------------------------------------- drawing ----

def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(str(FONT_DIR / name), size)
    except OSError:
        return ImageFont.load_default()


def render_sketch(path: Path) -> None:
    map_w, panel_w, h = 1400, 560, 1400
    cx, cy, radius = map_w / 2, h / 2 + 20, 590
    theta, rn = polar_grid(map_w, h, cx, cy, radius)
    codes = classify(theta, rn)

    rgb = np.zeros((h, map_w, 3), dtype=np.uint8)
    for code, d in DISTRICTS.items():
        rgb[codes == code] = d.color

    # fog gets soft noise so it reads as "outside"
    rng = np.random.default_rng(7)
    fog = codes == "FOG"
    noise = rng.normal(0, 9, (h, map_w))
    for c in range(3):
        ch = rgb[..., c].astype(float)
        ch[fog] = np.clip(ch[fog] - 40 * np.clip(1.4 - rn[fog], 0, 1) + noise[fog], 120, 235)
        rgb[..., c] = ch.astype(np.uint8)

    # borders where the district changes
    ids = np.zeros(codes.shape, dtype=np.int16)
    for i, code in enumerate(DISTRICTS):
        ids[codes == code] = i
    edge = np.zeros(ids.shape, dtype=bool)
    edge[:, 1:] |= ids[:, 1:] != ids[:, :-1]
    edge[1:, :] |= ids[1:, :] != ids[:-1, :]
    border = Image.fromarray((edge * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    base = Image.fromarray(rgb)
    base.paste((40, 34, 30), mask=border)

    img = Image.new("RGB", (map_w + panel_w, h), (236, 228, 210))
    img.paste(base, (0, 0))
    dr = ImageDraw.Draw(img, "RGBA")

    # street hints: grid in the Avenues, tram ring, lift shafts
    av = Image.fromarray(((codes == "AVENUES") * 255).astype(np.uint8))
    grid = Image.new("L", (map_w, h), 0)
    gd = ImageDraw.Draw(grid)
    for x in range(0, map_w, 34):
        gd.line([(x, 0), (x, h)], fill=255, width=1)
    for y in range(0, h, 34):
        gd.line([(0, y), (map_w, y)], fill=255, width=1)
    grid_mask = Image.fromarray(np.minimum(np.array(grid), np.array(av)))
    img.paste((120, 110, 92), mask=grid_mask)

    r_tram = 0.52 * radius
    dr.ellipse([cx - r_tram, cy - r_tram, cx + r_tram, cy + r_tram], outline=(60, 50, 40, 150), width=3)
    for i in range(0, 360, 6):
        a0, a1 = math.radians(i), math.radians(i + 3)
        dr.line([(cx + math.sin(a0) * r_tram, cy - math.cos(a0) * r_tram),
                 (cx + math.sin(a1) * r_tram, cy - math.cos(a1) * r_tram)], fill=(236, 228, 210, 200), width=1)
    for deg, rr in [(126, 0.66), (136, 0.58), (158, 0.78), (152, 0.92)]:
        x, y = to_xy(deg, rr, cx, cy, radius)
        dr.ellipse([x - 14, y - 14, x + 14, y + 14], fill=(30, 26, 24, 230), outline=(200, 180, 140), width=2)

    # gates: gaps in the wall
    f_gate = font("georgiab.ttf", 20)
    for gname, gdeg in GATES.items():
        x, y = to_xy(gdeg, 1.035, cx, cy, radius)
        dr.rectangle([x - 16, y - 16, x + 16, y + 16], fill=(230, 205, 140), outline=(30, 26, 24), width=3)
        dr.text((x + {0: 0, 120: 70, 240: -70}[int(gdeg)], y + (-42 if gdeg == 0 else 48)), gname, font=f_gate, fill=(30, 26, 24), anchor="mm")

    # district labels
    f_lab = font("georgiab.ttf", 22)
    f_sub = font("georgiai.ttf", 15)
    for d in DISTRICTS.values():
        if d.code in ("WALL", "FOG", "EXCHANGE", "CROWN"):
            continue
        x, y = to_xy(*d.label_at, cx, cy, radius)
        _plate(dr, x, y, f"{d.char} - {d.name}", d.role, f_lab, f_sub)
    _plate(dr, cx - 20, cy + 52, "C - Crown Ward", "administration, nobility", f_lab, f_sub)

    # landmarks
    f_num = font("arialbd.ttf", 17)
    for num, _, deg, rr in LANDMARKS:
        x, y = to_xy(deg, rr, cx, cy, radius)
        dr.ellipse([x - 15, y - 15, x + 15, y + 15], fill=(250, 244, 228), outline=(120, 20, 20), width=3)
        dr.text((x, y), str(num), font=f_num, fill=(120, 20, 20), anchor="mm")

    # compass
    f_c = font("georgiab.ttf", 26)
    dr.polygon([(80, 60), (68, 110), (80, 100), (92, 110)], fill=(40, 34, 30))
    dr.text((80, 40), "N", font=f_c, fill=(40, 34, 30), anchor="mm")
    dr.text((map_w - 30, 30), "MISTVEIL (fog beyond the wall)", font=f_sub, fill=(70, 70, 70), anchor="rm")

    _legend(dr, map_w, panel_w, h)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def _plate(dr: ImageDraw.ImageDraw, x, y, title, sub, f_t, f_s) -> None:
    tw = max(dr.textlength(title, font=f_t), dr.textlength(sub, font=f_s))
    dr.rounded_rectangle([x - tw / 2 - 8, y - 22, x + tw / 2 + 8, y + 22], radius=6, fill=(250, 244, 228, 215),
                         outline=(40, 34, 30, 160))
    dr.text((x, y - 8), title, font=f_t, fill=(30, 26, 24), anchor="mm")
    dr.text((x, y + 12), sub, font=f_s, fill=(70, 60, 50), anchor="mm")


def _legend(dr: ImageDraw.ImageDraw, x0: int, w: int, h: int) -> None:
    f_h = font("georgiab.ttf", 30)
    f_s = font("georgiab.ttf", 20)
    f_t = font("georgia.ttf", 16)
    x = x0 + 28
    dr.text((x, 30), "HALLOWDEEP", font=f_h, fill=(30, 26, 24))
    dr.text((x, 68), "Upper City - district sketch (top-down, north up)", font=f_t, fill=(60, 50, 40))
    y = 110
    dr.text((x, y), "Districts", font=f_s, fill=(30, 26, 24))
    y += 32
    for d in DISTRICTS.values():
        dr.rectangle([x, y, x + 26, y + 20], fill=d.color, outline=(30, 26, 24))
        dr.text((x + 36, y + 10), f"{d.char}  {d.name}", font=f_t, fill=(30, 26, 24), anchor="lm")
        y += 27
    y += 14
    dr.text((x, y), "Landmarks", font=f_s, fill=(30, 26, 24))
    y += 32
    for num, name, _, _ in LANDMARKS:
        dr.text((x, y), f"{num:>2}  {name}", font=f_t, fill=(30, 26, 24))
        y += 23
    y += 14
    dr.text((x, y), "Dashed ring = tram line.  Black discs = lift shafts.", font=f_t, fill=(60, 50, 40))
    dr.text((x, y + 22), "Grid lines = numbered streets of the Avenues.", font=f_t, fill=(60, 50, 40))
    dr.text((x, y + 44), "Below the platform: see city_cross_section.png", font=f_t, fill=(60, 50, 40))


def render_cross_section(path: Path) -> None:
    w, h = 2150, 1000
    img = Image.new("RGB", (w, h), (226, 222, 212))
    dr = ImageDraw.Draw(img, "RGBA")
    f_t = font("georgiab.ttf", 22)
    f_s = font("georgia.ttf", 17)

    # sky + fog walls on both sides
    for i in range(0, 220):
        a = int(200 * (1 - i / 220))
        dr.line([(i, 0), (i, 620)], fill=(150, 150, 150, a))
        dr.line([(w - 400 - i, 0), (w - 400 - i, 620)], fill=(150, 150, 150, 0))
    dr.rectangle([0, 0, 120, 620], fill=(160, 160, 158, 200))
    dr.text((60, 300), "MIST\nVEIL", font=f_t, fill=(60, 60, 60), anchor="mm", align="center")

    layers = [
        # (y0, y1, colour, title, note)
        (300, 340, (120, 126, 136), "UPPER CITY - metal platform", "12 districts, Ringwall on the rim | Chapter 1"),
        (340, 470, (150, 140, 120), "TRANSITION ZONE", "slums hanging under the platform and on the ground | Chapter 2"),
        (470, 560, (120, 104, 84), "LOWER CITY - levels 6-5", "mines, Grey Communion, black-robed miners | Chapter 2"),
        (560, 640, (96, 82, 70), "LOWER CITY - level 4", "bodily mutations, fungal forests | Chapter 3"),
        (640, 720, (78, 66, 60), "LOWER CITY - level 3", "the 'no-longer-human', own laws | Chapter 3"),
        (720, 820, (58, 50, 50), "LEVELS 2-1 + RUINS OF THE OLD CAPITAL", "dragon bones, elder relics | finale"),
        (820, 900, (40, 30, 44), "THE UNDERDREAM FISSURE", "crack into the dream realm - final boss"),
    ]
    x0, x1 = 140, 1360
    for y0, y1, col, title, note in layers:
        dr.rectangle([x0, y0, x1, y1], fill=col)
        dr.line([(x0, y1), (x1, y1)], fill=(30, 26, 24), width=2)
        dr.text((x1 + 20, (y0 + y1) / 2 - 11), title, font=f_t, fill=(30, 26, 24), anchor="lm")
        dr.text((x1 + 20, (y0 + y1) / 2 + 13), note, font=f_s, fill=(60, 50, 40), anchor="lm")

    # skyline on the platform
    sky = [(180, 60), (260, 90), (330, 40), (420, 120), (520, 70), (560, 230), (600, 70), (700, 110),
           (760, 160), (820, 90), (900, 60), (980, 120), (1060, 80), (1140, 140), (1220, 70), (1300, 50)]
    for x, bh in sky:
        dr.rectangle([x, 300 - bh, x + 50, 300], fill=(70, 66, 70))
    dr.polygon([(575, 70), (585, 40), (595, 70)], fill=(70, 66, 70))  # spire tip
    dr.text((585, 30), "Vigil Spire", font=f_s, fill=(30, 26, 24), anchor="mm")
    dr.text((785, 120), "Crown Ward", font=f_s, fill=(30, 26, 24), anchor="mm")
    # ringwall
    for x in (x0, x1 - 30):
        dr.rectangle([x, 220, x + 30, 340], fill=(40, 36, 34))
    # supports + lifts
    for x in (260, 520, 960, 1220):
        dr.rectangle([x, 340, x + 26, 470], fill=(60, 56, 54))
    for x in (1040, 1090):
        dr.rectangle([x, 300, x + 18, 900 if x == 1090 else 720], fill=(20, 18, 18))
    dr.text((1065, 925), "Deepwright lift shafts", font=f_s, fill=(30, 26, 24), anchor="mm")
    # fissure glow
    dr.polygon([(600, 900), (650, 830), (690, 870), (720, 820), (780, 900)], fill=(150, 60, 160, 200))

    dr.text((140, 960), "Each layer opens in a later story chapter; districts above can change their look after events.",
            font=f_s, fill=(60, 50, 40))
    img.save(path)


def write_ascii(path: Path, cells: int = 44) -> None:
    """Same layout sampled on a coarse grid; each cell printed twice so it looks square in monospace."""
    radius = cells / 2 / 1.12
    centers = np.arange(cells) + 0.5
    xs, ys = np.meshgrid(centers, centers)
    dx, dy = xs - cells / 2, ys - cells / 2
    theta = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    codes = classify(theta, np.hypot(dx, dy) / radius)
    rows = [[DISTRICTS[c].char * 2 for c in row] for row in codes]
    for num, _, deg, rr in LANDMARKS:
        t = math.radians(deg)
        col = int(cells / 2 + math.sin(t) * rr * radius)
        row = int(cells / 2 - math.cos(t) * rr * radius)
        rows[row][col] = f"{num:02d}"
    legend = [f"{d.char} = {d.name} ({d.code})" for d in DISTRICTS.values()]
    marks = [f"{n:02d} = {name}" for n, name, _, _ in LANDMARKS]
    text = "\n".join("".join(r) for r in rows)
    path.write_text("HALLOWDEEP - Upper City, north is up\n\n" + text + "\n\nLegend:\n"
                    + "\n".join(legend) + "\n\nLandmarks:\n" + "\n".join(marks) + "\n", encoding="utf-8")


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    render_sketch(OUT_DIR / "city_sketch.png")
    render_cross_section(OUT_DIR / "city_cross_section.png")
    write_ascii(OUT_DIR / "city_grid.txt")
    print("written to", OUT_DIR)
