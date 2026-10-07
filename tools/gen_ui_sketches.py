"""Bloody Voice - UI layout sketches (GDD 21, 22). Writes into docs/assets/ui/:
  combat_layout.png     the combat screen (1920x1080) with numbered zones + legend underneath
  card_anatomy.png      one card, every part named
  tutorial_overlay.png  how a tutorial hint looks: dimmed screen, lit cut-out, pulsing frame, text bubble

Zone rectangles here are the layout contract for scenes/combat (GDD 21.2 lists the same numbers).
Run from the project root:  python tools/gen_ui_sketches.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "assets" / "ui"
FONT = "C:/Windows/Fonts/georgia.ttf"
FONT_BOLD = "C:/Windows/Fonts/georgiab.ttf"
W, H = 1920, 1080
INK = (43, 36, 32)
PARCHMENT = (236, 228, 210)
BRASS = (176, 138, 74)
BLOOD = (138, 28, 28)
FOG = (189, 189, 184)
STEEL = (110, 122, 138)

# number, Russian name, English name, rect (x0, y0, x1, y1), what it shows
ZONES = [
    (1, "Верхняя планка", "Top bar", (0, 0, 1920, 56),
     "заказ и цель, ход, время ночи; справа меню и настройки"),
    (2, "Сцена твари", "Creature stage", (520, 70, 1400, 640),
     "тварь крупно в центре на фоне района; ничего не закрывает её"),
    (3, "Намерения", "Intents", (700, 76, 1220, 176),
     "медальоны над головой: иконка + число; «дальше» — бледнее, справа"),
    (4, "Части тела", "Body parts", (760, 300, 1160, 520),
     "мишени прямо на теле твари: кольцо HP части, клик при прицеливании"),
    (5, "Табличка твари", "Creature plate", (660, 560, 1260, 660),
     "имя и ранг-печать; полоса HP с метками фаз; щит блока; статусы"),
    (6, "Журнал", "Log", (1560, 70, 1900, 420),
     "свёрнут во вкладку «Журнал», разворачивается по клику"),
    (7, "Охотник", "Hunter", (20, 640, 400, 900),
     "портрет-медальон; флаконы HP и Рассудка; щит блока; статусы"),
    (8, "Очки действия", "Action points", (420, 690, 560, 760),
     "три латунные лампы: горит = есть очко"),
    (9, "Оружие", "Weapon", (20, 560, 400, 630),
     "табличка ружья: патроны в барабане, перезарядка"),
    (10, "Рука", "Hand", (560, 760, 1360, 1080),
     "карты веером; наведённая поднимается и увеличивается"),
    (11, "Добор", "Draw pile", (40, 930, 170, 1065), "колода рубашкой вверх, число карт"),
    (12, "Сброс / Изгнание", "Discard / Exhaust", (1700, 930, 1900, 1065), "две стопки с числами"),
    (13, "Конец хода", "End turn", (1420, 800, 1680, 900), "латунный рычаг; светится, когда ходов не осталось"),
    (14, "Подсказка действия", "Prompt line", (560, 700, 1360, 750), "«Выберите цель», ошибки, итог карты"),
]


LABEL_AT = {4: "bottom", 5: "above", 8: "above"}  # where a zone's label goes when the top is crowded


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT, size)


def badge(d: ImageDraw.ImageDraw, x: float, y: float, n: int, r: int = 22) -> None:
    d.ellipse([x - r, y - r, x + r, y + r], fill=BLOOD, outline=PARCHMENT, width=3)
    d.text((x, y), str(n), font=font(24, True), fill=PARCHMENT, anchor="mm")


def combat_layout() -> Image.Image:
    img = Image.new("RGB", (W, H + 470), (26, 22, 20))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 0, W, H], fill=(48, 40, 36))
    d.text((300, 200), "фон: сцена района, затемнена", font=font(22), fill=(110, 100, 92), anchor="mm")
    _creature(d)
    _hand(d)
    for n, ru, _en, (x0, y0, x1, y1), _ in ZONES:
        d.rectangle([x0, y0, x1, y1], outline=BRASS + (255,), width=3)
        ly = {"bottom": y1 - 34, "above": y0 - 34}.get(LABEL_AT.get(n, ""), y0 + 4)
        badge(d, x0 + 16, ly + 14, n, 15)
        d.text((x0 + 36, ly + 2), ru, font=font(18, True), fill=PARCHMENT, stroke_width=3, stroke_fill=(26, 22, 20))
    _legend(d, H + 20)
    return img


def _creature(d: ImageDraw.ImageDraw) -> None:
    d.ellipse([820, 180, 1100, 540], fill=(70, 62, 58), outline=(120, 110, 100), width=3)
    d.text((960, 250), "ТВАРЬ", font=font(40, True), fill=(140, 130, 120), anchor="mm")
    for x, num, kind in ((800, "8", "атака"), (900, "4", "страх")):
        d.ellipse([x, 100, x + 70, 170], fill=(90, 70, 40), outline=BRASS, width=4)
        d.text((x + 35, 128), num, font=font(26, True), fill=PARCHMENT, anchor="mm")
        d.text((x + 35, 154), kind, font=font(13), fill=FOG, anchor="mm")
    d.ellipse([1040, 108, 1094, 162], fill=(60, 52, 40), outline=(120, 100, 70), width=3)
    d.text((1067, 135), "?", font=font(20, True), fill=FOG, anchor="mm")
    d.text((1110, 135), "дальше", font=font(16), fill=FOG, anchor="lm")
    for x, y, name in ((880, 340, "Челюсть"), (1010, 460, "Лапы")):
        d.ellipse([x - 28, y - 28, x + 28, y + 28], outline=(220, 80, 60), width=5)
        d.arc([x - 36, y - 36, x + 36, y + 36], 0, 260, fill=BLOOD, width=6)
        d.text((x, y + 46), name, font=font(16, True), fill=PARCHMENT, anchor="mm")
    d.rectangle([700, 610, 1220, 628], fill=(30, 10, 10))
    d.rectangle([700, 610, 1060, 628], fill=BLOOD)
    for t in (0.5, 0.25):
        x = 700 + 520 * t
        d.line([(x, 604), (x, 634)], fill=PARCHMENT, width=3)
    d.text((960, 590), "Сторожевой пёс   [P]", font=font(24, True), fill=BRASS, anchor="mm")


def _hand(d: ImageDraw.ImageDraw) -> None:
    for i in range(5):  # cards 200 x 290 (GDD 21.3) fanned inside zone 10
        x = 570 + i * 145
        lift = 30 if i == 2 else 0
        d.rounded_rectangle([x, 790 - lift, x + 200, 1080 - lift], radius=10, fill=(222, 210, 184), outline=INK, width=3)
        d.ellipse([x + 6, 796 - lift, x + 46, 836 - lift], fill=BRASS, outline=INK, width=2)
        d.text((x + 26, 816 - lift), "1", font=font(20, True), fill=INK, anchor="mm")
        d.rectangle([x + 14, 846 - lift, x + 186, 906 - lift], fill=(150, 140, 120))
    d.rounded_rectangle([1430, 810, 1670, 890], radius=12, fill=(90, 70, 40), outline=BRASS, width=4)
    d.text((1550, 850), "КОНЕЦ ХОДА", font=font(24, True), fill=PARCHMENT, anchor="mm")
    for i in range(3):
        d.ellipse([440 + i * 40, 708, 472 + i * 40, 740], fill=(230, 180, 80) if i < 2 else (70, 60, 50), outline=INK)
    for i in range(5):
        d.rectangle([180 + i * 34, 590, 196 + i * 34, 622], fill=BRASS if i < 3 else (70, 60, 50), outline=INK)
    d.ellipse([40, 690, 160, 810], fill=(80, 70, 64), outline=BRASS, width=4)
    for x, col in ((200, BLOOD), (270, (107, 90, 154))):
        d.rounded_rectangle([x, 690, x + 44, 870], radius=18, outline=PARCHMENT, width=3)
        d.rounded_rectangle([x + 4, 760, x + 40, 866], radius=14, fill=col)


def _legend(d: ImageDraw.ImageDraw, y0: int) -> None:
    d.text((40, y0), "Экран боя — раскладка (GDD §21). Номера = зоны в тексте и в коде.", font=font(26, True), fill=BRASS)
    col_w = 940
    for i, (n, ru, en, _rect, what) in enumerate(ZONES):
        x = 40 + (i % 2) * col_w
        y = y0 + 50 + (i // 2) * 56
        badge(d, x + 16, y + 14, n, 15)
        d.text((x + 42, y), f"{ru} ({en})", font=font(20, True), fill=PARCHMENT)
        d.text((x + 42, y + 26), what, font=font(17), fill=FOG)


def card_anatomy() -> Image.Image:
    img = Image.new("RGB", (900, 620), (26, 22, 20))
    d = ImageDraw.Draw(img)
    x0, y0, cw, ch = 60, 40, 300, 420
    d.rounded_rectangle([x0, y0, x0 + cw, y0 + ch], radius=16, fill=(222, 210, 184), outline=BLOOD, width=6)
    parts = [
        ((x0 + 8, y0 + 8, x0 + 64, y0 + 64), "1", "Стоимость — латунная шестерня с числом AP"),
        ((x0 + 70, y0 + 14, x0 + cw - 12, y0 + 58), "2", "Лента с названием"),
        ((x0 + 16, y0 + 68, x0 + cw - 16, y0 + 220), "3", "Окно арта (гравюра действия)"),
        ((x0 + 16, y0 + 226, x0 + cw - 16, y0 + 256), "4", "Тип: иконка + цвет рамки (атака, защита…)"),
        ((x0 + 16, y0 + 262, x0 + cw - 16, y0 + 372), "5", "Текст эффекта (собирается из эффектов)"),
        ((x0 + 16, y0 + 378, x0 + 120, y0 + 410), "6", "Патроны: пули, если карта стреляет"),
        ((x0 + 150, y0 + 378, x0 + cw - 16, y0 + 410), "7", "Источник: модуль/оружие (мелко)"),
    ]
    for i, (rect, n, text) in enumerate(parts):
        d.rectangle(rect, outline=INK, width=2)
        badge(d, rect[2] - 4, rect[1] + 4, int(n), 13)
        d.text((420, 60 + i * 64), f"{n}. {text}", font=font(20), fill=PARCHMENT)
    d.text((420, 520), "Рамка: пергамент на латунном каркасе;", font=font(18), fill=FOG)
    d.text((420, 546), "наведение — карта поднимается и растёт ×1.25.", font=font(18), fill=FOG)
    return img


def tutorial_overlay() -> Image.Image:
    base = combat_layout().crop((0, 0, W, H))
    mask = Image.new("L", (W, H), 255)
    hole = (620, 760, 1380, 1078)
    ImageDraw.Draw(mask).rounded_rectangle(hole, radius=18, fill=0)
    base.paste(Image.new("RGB", (W, H), (0, 0, 0)), (0, 0), Image.eval(mask, lambda v: v * 185 // 255))
    d = ImageDraw.Draw(base)
    d.rounded_rectangle([hole[0] - 6, hole[1] - 6, hole[2] + 6, hole[3] + 6], radius=22, outline=(240, 200, 110), width=6)
    bx0, by0, bx1, by1 = 640, 470, 1360, 690
    d.rounded_rectangle([bx0, by0, bx1, by1], radius=14, fill=(236, 228, 210), outline=BRASS, width=4)
    d.polygon([(990, by1), (1030, by1), (1010, by1 + 40)], fill=(236, 228, 210))
    d.text((bx0 + 24, by0 + 18), "Рука", font=font(28, True), fill=BLOOD)
    d.text((bx0 + 24, by0 + 64), "Ваши карты на этот ход. Каждая стоит очки действия —", font=font(22), fill=INK)
    d.text((bx0 + 24, by0 + 94), "цифра в шестерёнке.", font=font(22), fill=INK)
    d.text((bx0 + 24, by1 - 44), "3 / 9", font=font(18), fill=(120, 110, 100))
    d.rounded_rectangle([bx1 - 300, by1 - 56, bx1 - 170, by1 - 16], radius=8, outline=INK, width=2)
    d.text((bx1 - 235, by1 - 36), "Пропустить", font=font(18), fill=INK, anchor="mm")
    d.rounded_rectangle([bx1 - 150, by1 - 56, bx1 - 24, by1 - 16], radius=8, fill=BRASS, outline=INK, width=2)
    d.text((bx1 - 87, by1 - 36), "Далее", font=font(20, True), fill=INK, anchor="mm")
    return base


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    combat_layout().save(OUT / "combat_layout.png")
    card_anatomy().save(OUT / "card_anatomy.png")
    tutorial_overlay().save(OUT / "tutorial_overlay.png")
    print("written ->", OUT)


if __name__ == "__main__":
    main()
