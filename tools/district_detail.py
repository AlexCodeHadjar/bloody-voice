"""Detailed drawing for tools/gen_district_sketch.py: house terraces along streets, the sunken gully with the
Candle Bridge, the aqueduct on piers, the Ringwall with the Edge Walk, district borders (no walls), lamps,
bonfires and landmark footprints. Everything takes `sk` (C space -> sketch px) and `k` (sketch px per C px).
"""
from __future__ import annotations

import math
import random
from typing import Callable

from PIL import Image, ImageDraw

Pt = tuple[float, float]
Map = Callable[[Pt], Pt]
INK = (43, 36, 32)
ROOFS = [(86, 92, 102), (104, 98, 92), (118, 84, 72), (94, 102, 112), (112, 106, 98), (76, 80, 88)]
ROAD = (176, 168, 152)
LAMP = (240, 190, 90)


def _unit(a: Pt, b: Pt) -> tuple[Pt, Pt, float]:
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy) or 1.0
    return (dx / length, dy / length), (-dy / length, dx / length), length


def _quad(c: Pt, u: Pt, n: Pt, w: float, h: float) -> list[Pt]:
    return [(c[0] + u[0] * sx * w / 2 + n[0] * sy * h / 2, c[1] + u[1] * sx * w / 2 + n[1] * sy * h / 2)
            for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def _free(mask: Image.Image, pts: list[Pt]) -> bool:
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    for x, y in pts + [(cx, cy)]:
        if not (0 <= x < mask.width and 0 <= y < mask.height) or mask.getpixel((int(x), int(y))) == 0:
            return False
    return True


def roof(d: ImageDraw.ImageDraw, pts: list[Pt], colour: tuple, ridge: bool = True) -> None:
    """A roof seen from above: slate colour, dark edge, a ridge along the long side."""
    d.polygon(pts, fill=colour, outline=INK)
    if ridge:
        a, b, c, e = pts
        if math.dist(a, b) >= math.dist(b, c):
            d.line([((a[0] + e[0]) / 2, (a[1] + e[1]) / 2), ((b[0] + c[0]) / 2, (b[1] + c[1]) / 2)], fill=INK, width=1)
        else:
            d.line([((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), ((e[0] + c[0]) / 2, (e[1] + c[1]) / 2)], fill=INK, width=1)


def terraces(d: ImageDraw.ImageDraw, free: Image.Image, streets: list[list[Pt]], widths: list[int],
             rnd: random.Random) -> None:
    """Rows of narrow houses facing every street (front row and a back-to-back second row), then yards."""
    fd = ImageDraw.Draw(free)
    for pts, width in zip(streets, widths):
        half = {0: 3, 1: 7, 2: 11, 3: 16}[width]
        for a, b in zip(pts, pts[1:]):
            u, n, length = _unit(a, b)
            for side in (1, -1):
                for row, gap in ((0, 3), (1, 28), (2, 53)):
                    t = 10.0
                    while t < length - 10:
                        w, depth = rnd.uniform(13, 22), rnd.uniform(15, 22)
                        off = half + gap + depth / 2
                        c = (a[0] + u[0] * (t + w / 2) + n[0] * side * off, a[1] + u[1] * (t + w / 2) + n[1] * side * off)
                        q = _quad(c, u, n, w, depth)
                        if _free(free, q):
                            roof(d, q, rnd.choice(ROOFS))
                            fd.polygon(_quad(c, u, n, w + 2, depth + 2), fill=0)
                        t += w + (rnd.uniform(6, 10) if rnd.random() < 0.12 else rnd.uniform(0.5, 2))


def yards(d: ImageDraw.ImageDraw, free: Image.Image, rnd: random.Random, count: int,
          size: tuple[float, float] = (9, 18), streets: list[list[Pt]] | None = None) -> None:
    """Back houses and sheds in what is left (yards stay as bare ground), turned like the nearest street."""
    segs = [(a, b) for pts in (streets or []) for a, b in zip(pts, pts[1:])]
    fd = ImageDraw.Draw(free)
    for _ in range(count):
        x, y = rnd.uniform(0, free.width), rnd.uniform(0, free.height)
        w, h = rnd.uniform(*size), rnd.uniform(size[0] * 0.9, size[1] * 0.85)
        ang = _street_angle(segs, (x, y)) + rnd.choice((0.0, math.pi / 2)) if segs else rnd.uniform(0, math.pi)
        u, n = (math.cos(ang), math.sin(ang)), (-math.sin(ang), math.cos(ang))
        q = _quad((x, y), u, n, w, h)
        if _free(free, q):
            roof(d, q, rnd.choice(ROOFS), ridge=w > 12)
            fd.polygon(_quad((x, y), u, n, w + 3, h + 3), fill=0)


def _street_angle(segs: list[tuple[Pt, Pt]], p: Pt) -> float:
    """Direction of the street segment nearest to p."""
    def dist(seg: tuple[Pt, Pt]) -> float:
        (ax, ay), (bx, by) = seg
        t = max(0.0, min(1.0, ((p[0] - ax) * (bx - ax) + (p[1] - ay) * (by - ay)) / (((bx - ax) ** 2 + (by - ay) ** 2) or 1)))
        return math.hypot(p[0] - ax - t * (bx - ax), p[1] - ay - t * (by - ay))
    (ax, ay), (bx, by) = min(segs, key=dist)
    return math.atan2(by - ay, bx - ax)


def street(d: ImageDraw.ImageDraw, pts: list[Pt], width: int) -> None:
    if width == 0:  # rope bridges between roofs
        for a, b in zip(pts, pts[1:]):
            u, n, length = _unit(a, b)
            d.line([a, b], fill=(120, 90, 50), width=3)
            for t in range(0, int(length), 9):
                p = (a[0] + u[0] * t, a[1] + u[1] * t)
                d.line([(p[0] - n[0] * 4, p[1] - n[1] * 4), (p[0] + n[0] * 4, p[1] + n[1] * 4)], fill=(120, 90, 50), width=1)
        return
    w = {1: 13, 2: 21, 3: 31}[width]
    d.line(pts, fill=(90, 84, 76), width=w + 4, joint="curve")
    d.line(pts, fill=ROAD, width=w, joint="curve")


def lamps(d: ImageDraw.ImageDraw, pts: list[Pt], width: int) -> None:
    """Gas lamps along streets: dots on alternating sides."""
    if width < 2:
        return
    half = {2: 12, 3: 17}[width]
    i = 0
    for a, b in zip(pts, pts[1:]):
        u, n, length = _unit(a, b)
        for t in range(14, int(length) - 6, 34):
            s = 1 if i % 2 else -1
            p = (a[0] + u[0] * t + n[0] * s * half, a[1] + u[1] * t + n[1] * s * half)
            d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=LAMP, outline=INK)
            i += 1


def gully(d: ImageDraw.ImageDraw, poly: list[Pt], rnd: random.Random) -> None:
    """The sunken hollow: dark floor, stepped rims (contour lines), fog patches."""
    d.polygon(poly, fill=(74, 78, 84), outline=INK)
    cx = sum(p[0] for p in poly) / len(poly)
    cy = sum(p[1] for p in poly) / len(poly)
    for f in (0.85, 0.7):
        d.line([(cx + (x - cx) * f, cy + (y - cy) * f) for x, y in poly + poly[:1]], fill=(60, 62, 68), width=2)
    d.polygon(poly, fill=(196, 198, 204, 70))  # fog lying evenly in the gully (no round blobs)


def bridge(d: ImageDraw.ImageDraw, a: Pt, b: Pt) -> None:
    """Candle Bridge from above: stone deck, parapets with candles, piers below, shadow on the gully floor."""
    u, n, length = _unit(a, b)
    deck = 24
    shadow = [(p[0] + 10, p[1] + 14) for p in _quad(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), u, n, length, deck)]
    d.polygon(shadow, fill=(30, 30, 34, 150))
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    d.polygon(_quad(mid, u, n, length, deck), fill=(150, 142, 128), outline=INK)
    for s in (1, -1):
        p0 = (a[0] + n[0] * s * deck / 2, a[1] + n[1] * s * deck / 2)
        p1 = (b[0] + n[0] * s * deck / 2, b[1] + n[1] * s * deck / 2)
        d.line([p0, p1], fill=(96, 90, 82), width=4)
        for t in range(6, int(length) - 4, 7):
            c = (p0[0] + u[0] * t, p0[1] + u[1] * t)
            d.ellipse([c[0] - 1.6, c[1] - 1.6, c[0] + 1.6, c[1] + 1.6], fill=LAMP)


def aqueduct(d: ImageDraw.ImageDraw, a: Pt, b: Pt) -> None:
    """Raised brick aqueduct from above: narrow deck, pier ends showing, long shadow to the south-east."""
    u, n, length = _unit(a, b)
    deck = 18
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    d.polygon([(p[0] + 16, p[1] + 22) for p in _quad(mid, u, n, length, deck)], fill=(30, 30, 34, 140))
    d.polygon(_quad(mid, u, n, length, deck), fill=(134, 96, 78), outline=INK)
    d.line([(a[0], a[1]), (b[0], b[1])], fill=(170, 150, 120), width=4)
    for t in range(18, int(length), 32):
        c = (a[0] + u[0] * t, a[1] + u[1] * t)
        d.polygon(_quad(c, u, n, 8, deck + 10), fill=(110, 78, 62), outline=INK)


def ringwall(d: ImageDraw.ImageDraw, inner: list[Pt], outer: list[Pt]) -> None:
    """The Ringwall as a fortress wall: about three houses thick, an inner face in deep shadow, a walkway with
    crenellations on top, big square towers, the abyss fog beyond; the Edge Walk ledge at its inner foot."""
    outer = [(p[0] + (q[0] - p[0]) * 2.0, p[1] + (q[1] - p[1]) * 2.0) for p, q in zip(inner, outer)]
    far = [(p[0] + 2000, p[1]) for p in outer]
    d.polygon(outer + far[::-1], fill=(150, 152, 158))  # the abyss: fog
    at = lambda f: [(p[0] + (q[0] - p[0]) * f, p[1] + (q[1] - p[1]) * f) for p, q in zip(inner, outer)]  # noqa: E731
    d.polygon(inner + outer[::-1], fill=(112, 106, 98), outline=INK, width=3)
    d.polygon(inner + at(0.18)[::-1], fill=(62, 58, 54))           # inner face, in shadow
    d.polygon(at(0.35) + at(0.65)[::-1], fill=(132, 126, 116))     # walkway on top
    for p in at(0.82)[::2]:                                         # crenellations on the outer parapet
        d.rectangle([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], fill=(90, 84, 78), outline=INK)
    for i in range(0, len(outer) - 1, 14):                         # big square towers
        u, n, _ = _unit(outer[i], outer[i + 1])
        c = ((inner[i][0] + outer[i][0]) / 2, (inner[i][1] + outer[i][1]) / 2)
        d.polygon(_quad(c, u, n, 46, math.dist(inner[i], outer[i]) + 30), fill=(100, 94, 88), outline=INK, width=3)
    inward = [(p[0] - (q[0] - p[0]) * 0.25, p[1] - (q[1] - p[1]) * 0.25) for p, q in zip(inner, outer)]
    d.polygon(inner + inward[::-1], fill=(20, 18, 20, 90))          # the wall's shadow on the Edge Walk
    ledge = [(p[0] - (q[0] - p[0]) * 0.12, p[1] - (q[1] - p[1]) * 0.12) for p, q in zip(inner, outer)]
    d.line(ledge, fill=(180, 172, 156), width=7)
    d.line(inner, fill=INK, width=2)
    for i in range(0, len(ledge), 3):
        d.ellipse([ledge[i][0] - 2.5, ledge[i][1] - 2.5, ledge[i][0] + 2.5, ledge[i][1] + 2.5], fill=LAMP)


def border(d: ImageDraw.ImageDraw, pts: list[Pt], kind: str) -> None:
    """A district edge that is NOT a wall: tram embankment, boundary street or railway viaduct."""
    if kind == "rail":
        d.line(pts, fill=(60, 54, 48), width=40, joint="curve")
        d.line(pts, fill=(98, 88, 76), width=34, joint="curve")
        for s in (-6, 6):
            d.line([(x + s * 0.7, y + s * 0.7) for x, y in pts], fill=(200, 196, 186), width=2)
        for a, b in zip(pts, pts[1:]):
            u, n, length = _unit(a, b)
            for t in range(0, int(length), 8):
                c = (a[0] + u[0] * t, a[1] + u[1] * t)
                d.line([(c[0] - n[0] * 10, c[1] - n[1] * 10), (c[0] + n[0] * 10, c[1] + n[1] * 10)], fill=(50, 44, 38), width=2)
    elif kind == "viaduct":
        d.line([(x + 10, y + 14) for x, y in pts], fill=(30, 30, 34, 140), width=26)
        d.line(pts, fill=(120, 96, 82), width=26, joint="curve")
        d.line(pts, fill=(60, 58, 56), width=2)
    elif kind == "street":
        d.line(pts, fill=(90, 84, 76), width=26, joint="curve")
        d.line(pts, fill=ROAD, width=22, joint="curve")


def bonfire(d: ImageDraw.ImageDraw, p: Pt) -> None:
    d.ellipse([p[0] - 7, p[1] - 7, p[0] + 7, p[1] + 7], fill=(230, 120, 40), outline=(90, 40, 20), width=2)
    d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=(255, 220, 120))


def landmark(d: ImageDraw.ImageDraw, c: Pt, w: float, h: float, kind: str, rnd: random.Random) -> None:
    """Footprint by kind, so ChatGPT sees what the building is from above."""
    x, y = c
    box = [x - w / 2, y - h / 2, x + w / 2, y + h / 2]
    if kind == "chapel":
        nave = [x - w * 0.18, y - h / 2, x + w * 0.18, y + h / 2]
        arms = [x - w * 0.62, y - h * 0.16, x + w * 0.62, y + h * 0.1]
        for r in (nave, arms):
            d.rectangle(r, fill=(108, 110, 120), outline=INK, width=3)
        d.rectangle([x - w * 0.62, y - h * 0.16, x - w * 0.1, y + h * 0.1], fill=(70, 66, 62), outline=INK, width=2)
        for i in range(6):  # collapsed roof: bare timber ribs
            xx = x - w * 0.58 + i * w * 0.08
            d.line([(xx, y - h * 0.14), (xx, y + h * 0.08)], fill=(150, 110, 70), width=2)
        d.rectangle([x - 16, y - h / 2 - 22, x + 16, y - h / 2 + 8], fill=(90, 92, 100), outline=INK, width=3)
        d.rectangle([x + w * 0.22, y - h * 0.48, x + w * 0.7, y + h * 0.5], outline=(70, 66, 60), width=3)  # yard wall
    elif kind == "tower":
        d.polygon([(box[2], box[1]), (box[2] + 40, box[1] + 50), (box[2] + 40, box[3] + 50), (box[2], box[3])],
                  fill=(30, 30, 34, 140))
        d.rectangle(box, fill=(96, 96, 104), outline=INK, width=3)
        d.line([(box[0], box[1]), (box[2], box[3])], fill=INK)
        d.line([(box[0], box[3]), (box[2], box[1])], fill=INK)
    elif kind == "market":
        d.rectangle(box, fill=(150, 140, 120), outline=INK, width=2)
        for i in range(14):
            sx, sy = rnd.uniform(box[0] + 6, box[2] - 16), rnd.uniform(box[1] + 6, box[3] - 14)
            d.rectangle([sx, sy, sx + 11, sy + 8], fill=rnd.choice([(200, 190, 160), (160, 120, 90), (120, 130, 110)]),
                        outline=INK)
    elif kind == "square":
        d.ellipse(box, fill=(160, 150, 130), outline=INK, width=2)
        d.rectangle([x + 18, y - 4, x + 26, y + 4], fill=(70, 60, 50))  # the leaflet post
    elif kind == "graveyard":
        d.rectangle(box, fill=(92, 100, 84), outline=(70, 66, 60), width=4)
        for gx in range(int(box[0]) + 10, int(box[2]) - 6, 14):
            for gy in range(int(box[1]) + 10, int(box[3]) - 6, 14):
                d.line([(gx, gy - 4), (gx, gy + 4)], fill=INK)
                d.line([(gx - 3, gy - 1), (gx + 3, gy - 1)], fill=INK)
    elif kind == "hoist":
        d.rectangle(box, outline=INK, width=4)
        d.line([(box[0], box[1]), (box[2], box[3])], fill=INK, width=2)
        d.line([(box[0], box[3]), (box[2], box[1])], fill=INK, width=2)
    elif kind == "cellar":
        for i in range(3):
            d.rectangle([x - w / 2 + i * w / 3 + 2, y - 8, x - w / 2 + (i + 1) * w / 3 - 2, y + 8], fill=(40, 40, 46),
                        outline=INK)
    elif kind == "depot":  # long shed roofs, tracks running in from the west, a turntable in the yard
        for i in range(3):
            y0 = box[1] + i * h / 3
            roof(d, [(box[0] + w * 0.3, y0 + 2), (box[2], y0 + 2), (box[2], y0 + h / 3 - 2), (box[0] + w * 0.3, y0 + h / 3 - 2)],
                 (78, 74, 70))
            d.line([(box[0] - 20, y0 + h / 6), (box[0] + w * 0.3, y0 + h / 6)], fill=(210, 205, 195), width=2)
        d.ellipse([box[0] - 8, y - 14, box[0] + 20, y + 14], outline=(210, 205, 195), width=3)
    elif kind == "gate":
        d.rectangle(box, fill=(70, 64, 58), outline=INK, width=3)
        d.arc([x - w * 0.3, y - h * 0.6, x + w * 0.3, y + h * 0.6], 180, 360, fill=(200, 160, 90), width=3)
    elif kind in ("shrine", "walk", "bridge", "aqueduct"):
        pass  # drawn as part of the wall / bridge / aqueduct
    else:
        colour = {"tavern": (124, 78, 52), "home": (116, 96, 70), "shop": (110, 92, 70), "workshop": (96, 90, 84),
                  "crypt": (100, 100, 108), "infirmary": (130, 120, 112)}.get(kind, (110, 100, 92))
        roof(d, [(box[0], box[1]), (box[2], box[1]), (box[2], box[3]), (box[0], box[3])], colour)


def inside_or_near(outline: list[Pt], p: Pt, tolerance: float) -> bool:
    """Point in polygon (even-odd), or within `tolerance` of one of its vertices."""
    n, hit = len(outline), False
    for i in range(n):
        (ax, ay), (bx, by) = outline[i], outline[(i + 1) % n]
        if (ay > p[1]) != (by > p[1]) and p[0] < ax + (p[1] - ay) * (bx - ax) / (by - ay):
            hit = not hit
    return hit or min(math.dist(p, q) for q in outline) <= tolerance
