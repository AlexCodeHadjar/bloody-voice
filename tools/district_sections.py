"""Side views (cross-sections) for the Grey Chapels map, so ChatGPT understands heights: the Candle Bridge over
the Fog Hollow, the Old Aqueduct, the Ringwall with the Edge Walk, and the district borders (no walls).
Called by tools/gen_district_sketch.py -> docs/art-prompts/grey-chapels-map/for-owner/sections.png (+ for-gpt/sections_clean.png)
"""
from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont

INK = (43, 36, 32)
SKY = (58, 62, 70)
STONE = (120, 112, 100)
BRICK = (128, 92, 74)
FOG = (196, 198, 204)
LAMP = (240, 190, 90)
PAPER = (236, 228, 210)
W, H = 900, 520
CLEAN = {"on": False}  # True: no words at all, only the panel letter (the version given to ChatGPT)


class _Mute(ImageDraw.ImageDraw):
    """ImageDraw that ignores text: the same drawing without any words."""

    def text(self, *args, **kwargs) -> None:  # noqa: D102
        return None


def _font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def _house(d: ImageDraw.ImageDraw, x: int, ground: int, w: int, floors: int) -> None:
    top = ground - floors * 34
    d.rectangle([x, top, x + w, ground], fill=(84, 80, 76), outline=INK)
    d.polygon([(x - 4, top), (x + w / 2, top - 22), (x + w + 4, top)], fill=(70, 74, 82), outline=INK)
    for f in range(floors):
        for wx in range(x + 8, x + w - 10, 16):
            d.rectangle([wx, top + 10 + f * 34, wx + 7, top + 22 + f * 34], fill=LAMP if (wx + f) % 3 == 0 else (40, 40, 44))


def _panel(title: str, note: str, fonts: tuple) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (W, H), SKY)
    d = _Mute(img, "RGBA") if CLEAN["on"] else ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 0, W, 64], fill=(30, 26, 24))
    ImageDraw.ImageDraw.text(d, (18, 8), title[0] if CLEAN["on"] else title, font=fonts[0], fill=(217, 181, 106))
    d.text((18, 38), note, font=fonts[1], fill=PAPER)
    return img, d


def bridge_panel(fonts: tuple) -> Image.Image:
    img, d = _panel("A. Мост Свечей над Туманным логом (разрез)",
                    "Лог — провал на 2 этажа ниже улиц, в нём лежит туман. Мост — каменный, на уровне улиц, на одной арке.", fonts)
    ground, floor = 330, 440
    d.rectangle([0, ground, 260, H], fill=STONE, outline=INK)
    d.rectangle([640, ground, W, H], fill=STONE, outline=INK)
    d.rectangle([260, floor, 640, H], fill=(70, 72, 78))
    for x in (40, 130):
        _house(d, x, ground, 80, 3)
    for x in (680, 780):
        _house(d, x, ground, 80, 3)
    d.rectangle([250, ground - 10, 650, ground + 14], fill=(150, 142, 128), outline=INK)
    d.pieslice([300, ground - 2, 600, floor + 150], 180, 360, fill=SKY, outline=INK)
    for x in range(256, 646, 14):
        d.line([(x, ground - 10), (x, ground - 18)], fill=PAPER)
        d.ellipse([x - 2, ground - 24, x + 2, ground - 20], fill=LAMP)
    d.rectangle([262, 395, 638, floor], fill=FOG + (170,))
    d.text((360, 470), "туман на дне лога", font=fonts[1], fill=INK)
    d.text((290, ground - 50), "мост на уровне улиц", font=fonts[1], fill=PAPER)
    return img


def aqueduct_panel(fonts: tuple) -> Image.Image:
    img, d = _panel("B. Старый акведук (вид сбоку)",
                    "Кирпичные арки высотой ~4 этажа, наверху узкая тропа с перилами. Под арками — дворы и лачуги.", fonts)
    ground, deck = 470, 170
    d.rectangle([0, ground, W, H], fill=STONE)
    d.rectangle([20, deck, 880, ground], fill=BRICK, outline=INK)  # one brick wall, openings cut below
    for x in range(20, 870, 110):
        d.rectangle([x + 26, deck + 76, x + 110, ground], fill=SKY)
        d.pieslice([x + 26, deck + 34, x + 110, deck + 118], 180, 360, fill=SKY)
        d.arc([x + 26, deck + 34, x + 110, deck + 118], 180, 360, fill=INK, width=2)
    for x in range(20, 880, 12):
        d.line([(x, deck), (x, deck - 12)], fill=INK)
    d.line([(20, deck - 12), (880, deck - 12)], fill=INK, width=2)
    for x in (60, 280, 500, 720):
        _house(d, x, ground, 60, 2)
    d.text((340, deck - 44), "тропа по акведуку (ходить можно)", font=fonts[1], fill=PAPER)
    return img


def wall_panel(fonts: tuple) -> Image.Image:
    img, d = _panel("C. Кольцевая стена и Дорожка над Бездной (разрез)",
                    "Стена — сплошная, гладкая изнутри, дома к ней НЕ прилипают. Дорожка — уступ с перилами вдоль стены.", fonts)
    ground = 420
    d.rectangle([0, ground, 520, H], fill=STONE)
    for x in (30, 140, 250):
        _house(d, x, ground, 90, 3)
    d.text((370, ground + 30), "улица", font=fonts[1], fill=INK)
    d.rectangle([520, 120, 680, H], fill=(98, 92, 86), outline=INK)
    d.rectangle([470, 330, 520, 350], fill=(180, 172, 156), outline=INK)
    d.line([(470, 300), (470, 330)], fill=INK, width=2)
    d.line([(470, 300), (520, 300)], fill=INK, width=2)
    for x in (480, 505):
        d.ellipse([x - 3, 310, x + 3, 316], fill=LAMP)
    d.text((300, 280), "Дорожка над Бездной (уступ)", font=fonts[1], fill=PAPER)
    d.rectangle([680, 64, W, H], fill=FOG)
    d.text((700, 300), "БЕЗДНА", font=fonts[0], fill=INK)
    d.text((700, 330), "туман, обрыв вниз", font=fonts[1], fill=INK)
    d.polygon([(680, 120), (700, 140), (680, 160)], fill=FOG)
    return img


def border_panel(fonts: tuple) -> Image.Image:
    img, d = _panel("D. Границы района — СТЕНЫ НЕТ",
                    "Запад — трамвайная насыпь, север — улица, юг — ж/д виадук. За ними дома соседей.", fonts)
    ground = 440
    d.rectangle([0, ground, W, H], fill=STONE)
    x0 = 20  # west: tram embankment
    d.polygon([(x0, ground), (x0 + 50, ground - 40), (x0 + 200, ground - 40), (x0 + 250, ground)], fill=(112, 104, 92), outline=INK)
    d.line([(x0 + 60, ground - 44), (x0 + 190, ground - 44)], fill=INK, width=3)
    d.text((x0 + 40, ground - 90), "насыпь с рельсами", font=fonts[1], fill=PAPER)
    x1 = 320  # north: street
    _house(d, x1, ground, 50, 3)
    _house(d, x1 + 170, ground, 50, 3)
    d.text((x1 + 60, ground + 20), "улица", font=fonts[1], fill=INK)
    x2 = 620  # south: viaduct
    d.rectangle([x2, 300, x2 + 260, 330], fill=BRICK, outline=INK)
    for x in (x2, x2 + 230):
        d.rectangle([x, 330, x + 30, ground], fill=BRICK, outline=INK)
    d.pieslice([x2 + 30, 320, x2 + 230, ground + 100], 180, 360, fill=SKY, outline=INK)
    d.text((x2 + 60, 260), "виадук, проход под ним", font=fonts[1], fill=PAPER)
    return img


def sections(font_bold: str, font_regular: str, clean: bool = False) -> Image.Image:
    CLEAN["on"] = clean
    fonts = (_font(font_bold, 26), _font(font_regular, 17))
    sheet = Image.new("RGB", (W * 2, H * 2), (26, 22, 20))
    for i, panel in enumerate((bridge_panel, aqueduct_panel, wall_panel, border_panel)):
        sheet.paste(panel(fonts), ((i % 2) * W, (i // 2) * H))
    return sheet
