"""Bloody Voice - layout sketches of the workshop and the skill webs (GDD 23). Writes into docs/assets/ui/:
  workshop_layout.png        the workshop screen (1920x1080) with numbered zones + legend underneath
  skills_mechanic_layout.png the skill web screen, Mechanic web open, numbered zones + legend
  skills_monster_layout.png  the same screen with the Monster web (the Voice) open

Uses the real imported art (module art, icons) so the sketch shows the actual look of the pieces.
Run from the project root:  python tools/gen_screen_sketches.py
"""
from __future__ import annotations

import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_ui_sketches import BLOOD, BRASS, FOG, INK, OUT, PARCHMENT, ROOT, STEEL, H, W, badge, font  # noqa: E402

ICONS = ROOT / "art" / "ui" / "icons"
MODULES = ROOT / "art" / "gear" / "modules"
BG = (40, 34, 31)
DIM = (95, 86, 78)
VIOLET = (107, 90, 154)


def icon(img: Image.Image, name: str, at: tuple[int, int], side: int) -> None:
    path = ICONS / f"{name}.webp"
    if not path.exists():
        print("missing icon", name)
    else:
        ic = Image.open(path).convert("RGBA").resize((side, side), Image.LANCZOS)
        img.paste(ic, at, ic)


def art(img: Image.Image, path: Path, box: tuple[int, int, int, int], dim: bool = False) -> None:
    if not path.exists():
        print("missing art", path.name)
        return
    a = Image.open(path).convert("RGBA")
    a.thumbnail((box[2] - box[0], box[3] - box[1]), Image.LANCZOS)
    if dim:
        a.putalpha(a.getchannel("A").point(lambda v: v * 2 // 5))
    img.paste(a, (box[0] + (box[2] - box[0] - a.width) // 2, box[1] + (box[3] - box[1] - a.height) // 2), a)


def zones(img: Image.Image, d: ImageDraw.ImageDraw, items: list[tuple], legend_title: str) -> None:
    for n, ru, rect, _what in items:
        x0, y0, x1, y1 = rect
        d.rectangle(rect, outline=BRASS, width=3)
        if y1 - y0 >= 70:
            badge(d, x0 + 16, y0 + 18, n, 15)
            d.text((x0 + 36, y0 + 6), ru, font=font(18, True), fill=PARCHMENT, stroke_width=3, stroke_fill=BG)
        elif y0 == 0:  # the top bar: label left of the exit button, clear of the content
            badge(d, x1 - 380, y0 + 18, n, 15)
            d.text((x1 - 360, y0 + 6), ru, font=font(18, True), fill=PARCHMENT, stroke_width=3, stroke_fill=BG)
        else:  # other thin bars: only the number, on the bar's left border (the legend names it)
            badge(d, x0, y0 + (y1 - y0) / 2, n, 13)
    y = H + 20
    d.text((40, y), legend_title, font=font(26, True), fill=BRASS)
    for i, (n, ru, _rect, what) in enumerate(items):
        x = 40 + (i % 2) * 940
        yy = y + 50 + (i // 2) * 56
        badge(d, x + 16, yy + 14, n, 15)
        d.text((x + 42, yy), ru, font=font(20, True), fill=PARCHMENT)
        d.text((x + 42, yy + 26), what, font=font(17), fill=FOG)


def exit_button(d: ImageDraw.ImageDraw) -> None:
    d.rounded_rectangle([1760, 12, 1904, 52], radius=8, fill=(70, 56, 40), outline=BRASS, width=2)
    d.text((1832, 32), "В район", font=font(18, True), fill=PARCHMENT, anchor="mm")


def resource_bar(img: Image.Image, d: ImageDraw.ImageDraw, x: int, y: int) -> None:
    for res, n in (("gears", 14), ("scrap", 22), ("electronics", 3), ("ichor", 5), ("trophy", 2), ("money", 60)):
        icon(img, f"RESOURCE__{res}", (x, y), 34)
        d.text((x + 40, y + 17), str(n), font=font(22, True), fill=PARCHMENT, anchor="lm")
        x += 105


# ---------------------------------------------------------------- workshop

WORKSHOP_ZONES = [
    (1, "Верхняя планка", (0, 0, 1920, 64), "название мастерской; ресурсы с числами; «Изготовлений сегодня: 2/2»; выход в район"),
    (2, "Вкладки чертежей", (20, 80, 560, 130), "Модули · Механизмы · Оружие · Броня · Расходники"),
    (3, "Фильтры", (20, 136, 560, 180), "секция (приклад…ствол), тип ячейки (шестерня/искра/кровь), «только доступные»"),
    (4, "Список чертежей", (20, 186, 560, 1060), "арт, имя, уровень I–III, цена иконками; нет ресурса — красным; нет чертежа — замок и где взять"),
    (5, "Верстак", (580, 80, 1340, 640), "выбранный чертёж крупно: арт на сетке клеток, уровень, эффект"),
    (6, "Что даст в колоде", (580, 650, 1340, 820), "мини-карты, которые модуль добавит/заменит, бонусы; сравнение с текущим"),
    (7, "Цена и кнопка", (580, 830, 1340, 1060), "нужно / есть по каждому ресурсу; «Изготовить» (1 работа); путь улучшений I » II » III"),
    (8, "Склад", (1360, 80, 1900, 860), "свои модули и механизмы: установлен / запасной, уровень"),
    (9, "Действия со складом", (1360, 870, 1900, 1060), "«Улучшить», «Разобрать (+50 % ресурсов)» с предпросмотром возврата, «К снаряжению»"),
]


def workshop() -> Image.Image:
    img = Image.new("RGB", (W, H + 360), (26, 22, 20))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 0, W, H], fill=BG)
    d.text((24, 32), "Мастерская «Ржавая Шестерня»", font=font(26, True), fill=BRASS, anchor="lm")
    resource_bar(img, d, 500, 15)
    exit_button(d)
    d.text((1140, 32), "Изготовлений сегодня: 2 / 2", font=font(20, True), fill=PARCHMENT, anchor="lm")
    _tabs(d)
    _blueprints(img, d)
    _bench(img, d)
    _stash(img, d)
    zones(img, d, WORKSHOP_ZONES, "Мастерская — раскладка (GDD §23.1). Номера = зоны в тексте и в коде.")
    return img


def _tabs(d: ImageDraw.ImageDraw) -> None:
    x = 50
    for i, t in enumerate(("Модули", "Механизмы", "Оружие", "Броня", "Расходники")):
        w = d.textlength(t, font=font(15, True)) + 12
        d.rounded_rectangle([x, 100, x + w, 126], radius=6, fill=BRASS if i == 0 else (60, 52, 46), outline=INK)
        d.text((x + w / 2, 113), t, font=font(15, True), fill=INK if i == 0 else FOG, anchor="mm")
        x += w + 4
    d.text((50, 160), "Секция: все    Ячейка: все    [ ] только доступные", font=font(16), fill=FOG, anchor="lm")


def _blueprints(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    rows = [("RIFLED_BARREL", "Нарезной ствол", "I", [("gears", 4), ("scrap", 3)], "ok"),
            ("HARPOON_LAUNCHER", "Гарпунная пушка", "I", [("gears", 6), ("scrap", 4)], "sel"),
            ("COIL_ACCELERATOR", "Катушечный ускоритель", "II", [("electronics", 4), ("gears", 2)], "poor"),
            ("BONE_BRACE", "Костяной упор", "I", [("ichor", 2), ("trophy", 1)], "ok"),
            ("QUICK_LOADER", "Быстрый заряжатель", "I", [("gears", 3), ("scrap", 2)], "ok"),
            ("ICHOR_CARTRIDGES", "Патроны с ихором", "I", [("ichor", 3), ("scrap", 2)], "ok"),
            ("VEIN_LATTICE", "Венозная решётка", "—", [("ichor", 6), ("trophy", 1)], "locked"),
            ]
    y = 220
    for code, name, tier, cost, state in rows:
        fill = (78, 60, 36) if state == "sel" else (50, 43, 38)
        d.rounded_rectangle([34, y, 546, y + 108], radius=8, fill=fill, outline=BRASS if state == "sel" else DIM, width=2)
        art(img, MODULES / f"{code}__module__normal.webp", (44, y + 8, 164, y + 100), dim=state == "locked")
        d.text((178, y + 22), name, font=font(19, True), fill=PARCHMENT if state != "locked" else DIM, anchor="lm")
        d.text((520, y + 22), tier, font=font(18, True), fill=BRASS, anchor="rm")
        if state == "locked":
            icon(img, "UI__lock", (178, y + 48), 28)
            d.text((212, y + 62), "Чертёж: ветка Механика / Лавка", font=font(15), fill=FOG, anchor="lm")
        else:
            x = 178
            for res, n in cost:
                icon(img, f"RESOURCE__{res}", (x, y + 50), 26)
                short = state == "poor" and res == "electronics"
                d.text((x + 30, y + 63), str(n), font=font(18, True), fill=(220, 70, 60) if short else PARCHMENT, anchor="lm")
                x += 80
        y += 118


def _bench(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    d.rounded_rectangle([600, 140, 1320, 620], radius=12, fill=(214, 200, 170), outline=BRASS, width=4)
    for c in range(3):
        d.rectangle([760 + c * 130, 300, 890 + c * 130, 430], outline=(150, 130, 100), width=2)
    art(img, MODULES / "HARPOON_LAUNCHER__module__normal.webp", (760, 300, 1150, 430))
    d.text((960, 175), "Гарпунная пушка · уровень I", font=font(26, True), fill=INK, anchor="mm")
    d.text((960, 210), "ствол · 3 клетки шестерни (I)", font=font(18), fill=(90, 75, 60), anchor="mm")
    d.text((960, 480), "Добавляет карту «Гарпун»: 12 урона, 1 патрон.", font=font(20), fill=INK, anchor="mm")
    d.text((960, 512), "С катушечным ускорителем рядом — «Шоковый гарпун».", font=font(18), fill=(90, 75, 60), anchor="mm")
    d.text((620, 686), "Колода сейчас", font=font(15, True), fill=FOG, anchor="lm")
    mini_card(d, (620, 696), "Выстрел", 1, "9 урона, 1 патрон", BLOOD, "×2")
    d.text((780, 745), "»", font=font(40, True), fill=BRASS, anchor="mm")
    d.text((820, 686), "После изготовления", font=font(15, True), fill=FOG, anchor="lm")
    mini_card(d, (820, 696), "Выстрел", 1, "9 урона, 1 патрон", BLOOD, "×2")
    mini_card(d, (960, 696), "Гарпун", 1, "12 урона, 1 патрон", BLOOD, "новая")
    d.text((1100, 715), "Карт: 15 » 16", font=font(17, True), fill=PARCHMENT, anchor="lm")
    d.text((1100, 745), "Рядом с ускорителем:", font=font(15), fill=FOG, anchor="lm")
    d.text((1100, 770), "Гарпун » Шоковый гарпун", font=font(15, True), fill=PARCHMENT, anchor="lm")
    for i, (res, need, have) in enumerate((("gears", 6, 14), ("scrap", 4, 22))):
        y = 860 + i * 44
        icon(img, f"RESOURCE__{res}", (620, y), 32)
        d.text((664, y + 16), f"нужно {need} · есть {have}", font=font(20), fill=PARCHMENT, anchor="lm")
    d.rounded_rectangle([960, 860, 1320, 940], radius=12, fill=(120, 92, 48), outline=BRASS, width=4)
    d.text((1140, 900), "ИЗГОТОВИТЬ", font=font(26, True), fill=PARCHMENT, anchor="mm")
    d.text((620, 990), "Улучшения:  [I] есть  »  [II] +4 урона: 4 шестерни, 1 трофей  »  [III]", font=font(18), fill=FOG, anchor="lm")


def mini_card(d: ImageDraw.ImageDraw, at: tuple[int, int], name: str, cost: int, text: str, col: tuple,
              tag: str) -> None:
    x, y = at
    d.rounded_rectangle([x, y, x + 120, y + 120], radius=8, fill=(222, 210, 184), outline=col, width=4)
    d.ellipse([x + 4, y + 4, x + 28, y + 28], fill=BRASS, outline=INK)
    d.text((x + 16, y + 16), str(cost), font=font(15, True), fill=INK, anchor="mm")
    d.text((x + 74, y + 18), name, font=font(14, True), fill=INK, anchor="mm")
    d.rectangle([x + 10, y + 34, x + 110, y + 70], fill=(170, 155, 130))
    d.text((x + 60, y + 88), text, font=font(11), fill=INK, anchor="mm")
    d.text((x + 60, y + 106), tag, font=font(12, True), fill=col, anchor="mm")


def _stash(img: Image.Image, d: ImageDraw.ImageDraw) -> None:
    items = [("BRASS_SCOPE", "Латунный прицел", "I · установлен"), ("DRUM_MAGAZINE", "Барабанный магазин", "I · запасной"),
             ("RECOIL_SPRING", "Возвратная пружина", "II · запасной"), ("LANTERN_LENS", "Линза фонаря", "I · запасной")]
    y = 140
    for code, name, info in items:
        sel = code == "RECOIL_SPRING"
        d.rounded_rectangle([1380, y, 1880, y + 150], radius=8, fill=(78, 60, 36) if sel else (50, 43, 38),
                            outline=BRASS if sel else DIM, width=3 if sel else 2)
        art(img, MODULES / f"{code}__module__normal.webp", (1390, y + 10, 1540, y + 140))
        d.text((1556, y + 50), name, font=font(19, True), fill=PARCHMENT, anchor="lm")
        d.text((1556, y + 84), info, font=font(16), fill=FOG, anchor="lm")
        y += 170
    for i, t in enumerate(("Улучшить до III: 1 изготовление, 5 шест.", "Разобрать: +2 шест., +1 лом", "К снаряжению")):
        d.rounded_rectangle([1380, 900 + i * 52, 1880, 940 + i * 52], radius=8, fill=(70, 56, 40), outline=BRASS, width=2)
        d.text((1630, 920 + i * 52), t, font=font(18, True), fill=PARCHMENT, anchor="mm")


# ---------------------------------------------------------------- skill webs

SKILL_ZONES = [
    (1, "Верхняя планка", (0, 0, 1920, 64), "уровень и полоса опыта; очки навыков и атрибутов; выход"),
    (2, "Вкладки веток", (380, 74, 1540, 120), "Механик · Тварь (Голос); у каждой свой цвет"),
    (3, "Паутина", (380, 126, 1540, 1000), "граф от центра: 4 направления, узлы покупаются от уже купленных; тянуть мышью, колесо — масштаб"),
    (4, "Атрибуты", (20, 74, 360, 560), "Воля, Ловкость, Хитрость: значение, «+», на что влияет"),
    (5, "Под-ветки снаряжения", (20, 570, 360, 1000), "Шлем · Нагрудник · Наручи · Поножи — переход к своему участку паутины"),
    (6, "Карточка узла", (1560, 74, 1900, 760), "имя, тип, эффект, цена (1 очко), требования; «Изучить»; чертёж: «Откроет в мастерской»"),
    (7, "Особенности ветки", (1560, 770, 1900, 1000), "Механик: найденные чертежи фракций; Тварь: шкала Голоса и образцы крови"),
    (8, "Легенда", (380, 1006, 1540, 1070), "круг — пассив, квадрат — чертёж, шестиугольник — гнездо, ромб — ключевой узел"),
]


def skills(monster: bool) -> Image.Image:
    img = Image.new("RGB", (W, H + 360), (26, 22, 20))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 0, W, H], fill=BG)
    accent = BLOOD if monster else BRASS
    d.text((24, 32), "Развитие охотника", font=font(26, True), fill=BRASS, anchor="lm")
    d.text((330, 32), "Уровень 4", font=font(22, True), fill=PARCHMENT, anchor="lm")
    d.rectangle([460, 24, 760, 40], fill=(30, 26, 24))
    d.rectangle([460, 24, 640, 40], fill=BRASS)
    icon(img, "STAT__xp", (770, 14), 36)
    icon(img, "STAT__skill_point", (900, 14), 36)
    d.text((942, 32), "Очки навыков: 2", font=font(20, True), fill=PARCHMENT, anchor="lm")
    d.text((1140, 32), "Очки атрибутов: 1", font=font(20, True), fill=PARCHMENT, anchor="lm")
    exit_button(d)
    for i, (t, on) in enumerate((("Ветка Механика", not monster), ("Ветка Твари — Голос", monster))):
        x = 620 + i * 340
        d.rounded_rectangle([x, 80, x + 320, 114], radius=8, fill=accent if on else (60, 52, 46), outline=INK)
        d.text((x + 160, 97), t, font=font(18, True), fill=(PARCHMENT if monster else INK) if on else FOG, anchor="mm")
    _web(img, d, monster, accent)
    _attributes(img, d, monster)
    _node_card(img, d, monster, accent)
    _special(img, d, monster)
    _skill_legend(d, accent, monster)
    title = "Ветка Твари (Голос)" if monster else "Ветка Механика"
    zones(img, d, SKILL_ZONES, f"Развитие — {title} (GDD §23.2). Номера = зоны в тексте и в коде.")
    return img


DIRECTIONS = [  # (Russian name, centre angle in degrees, spokes)
    ("Снаряжение", -90, 4), ("Оружие", 0, 2), ("Модули", 90, 3), ("Механизмы", 180, 2),
]
GEAR_SUBWEBS = ["Шлем", "Нагрудник", "Наручи", "Поножи"]


def _web(img: Image.Image, d: ImageDraw.ImageDraw, monster: bool, accent: tuple) -> None:
    cx, cy = 960, 565
    rnd = random.Random(3 if monster else 1)
    for r in (110, 200, 290, 375):
        d.ellipse([cx - r, cy - r * 0.95, cx + r, cy + r * 0.95], outline=(60, 54, 50), width=1)
    d.ellipse([cx - 34, cy - 34, cx + 34, cy + 34], fill=accent, outline=PARCHMENT, width=3)
    d.text((cx, cy), "Старт", font=font(15, True), fill=INK, anchor="mm")
    for name, ang, spokes in DIRECTIONS:
        d.text((cx + 440 * math.cos(math.radians(ang)), cy + 415 * math.sin(math.radians(ang))), name.upper(),
               font=font(20, True), fill=accent, anchor="mm", stroke_width=3, stroke_fill=BG)
        for s in range(spokes):
            a = math.radians(ang + (s - (spokes - 1) / 2) * 22)
            prev = (cx + 34 * math.cos(a), cy + 34 * math.sin(a))
            for ring, r in enumerate((110, 200, 290, 375)):
                p = (cx + r * math.cos(a), cy + r * 0.95 * math.sin(a))
                owned = ring == 0 or (ring == 1 and rnd.random() < 0.5)
                avail = not owned and ring <= 2 and rnd.random() < 0.6
                d.line([prev, p], fill=accent if owned else (90, 80, 72), width=4 if owned else 2)
                kind = "key" if ring == 3 and s == 0 else rnd.choice(["passive", "passive", "blueprint", "socket"])
                chosen = name == "Модули" and s == 1 and ring == 2  # the node shown in the node card
                if chosen:
                    kind, owned, avail = ("passive" if monster else "blueprint"), False, True
                _node(d, p, kind, owned, avail, accent, monster)
                if chosen:
                    d.ellipse([p[0] - 30, p[1] - 30, p[0] + 30, p[1] + 30], outline=PARCHMENT, width=3)
                if name == "Снаряжение" and ring == 3:
                    d.text((p[0], p[1] - 34), GEAR_SUBWEBS[s], font=font(14, True), fill=FOG, anchor="mm")
                prev = p
    d.text((1520, 150), "тяните мышью · колесо — масштаб", font=font(15), fill=DIM, anchor="rm")


def _node(d: ImageDraw.ImageDraw, p: tuple, kind: str, owned: bool, avail: bool, accent: tuple, monster: bool) -> None:
    x, y = p
    fill = accent if owned else (70, 62, 56)
    line = PARCHMENT if owned else (240, 200, 110) if avail else (110, 100, 92)
    w = 4 if avail else 2
    if kind == "passive":
        d.ellipse([x - 16, y - 16, x + 16, y + 16], fill=fill, outline=line, width=w)
    elif kind == "blueprint":
        d.rectangle([x - 16, y - 16, x + 16, y + 16], fill=fill, outline=line, width=w)
    elif kind == "socket":
        d.regular_polygon((x, y, 18), 6, fill=fill, outline=line, width=w)
    else:
        d.regular_polygon((x, y, 28), 4, rotation=45, fill=fill, outline=line, width=w)
    if monster and kind != "key" and not owned:
        d.ellipse([x + 10, y - 22, x + 22, y - 10], fill=BLOOD)  # needs a blood sample


def _attributes(img: Image.Image, d: ImageDraw.ImageDraw, monster: bool) -> None:
    rows = [("will", "Воля", 3, "рассудок,\nпороги Голоса"), ("agility", "Ловкость", 2, "добор карт,\nуклонение, поиск"),
            ("cunning", "Хитрость", 2, "намерения,\nпоимка, цены")]
    for i, (code, name, val, what) in enumerate(rows):
        y = 130 + i * 140
        icon(img, f"ATTRIBUTE__{code}", (40, y), 70)
        d.text((124, y + 18), f"{name}  {val}", font=font(24, True), fill=PARCHMENT, anchor="lm")
        d.multiline_text((124, y + 42), what, font=font(15), fill=FOG, spacing=2)
        d.rounded_rectangle([300, y + 10, 340, y + 50], radius=6, fill=BRASS, outline=INK)
        d.text((320, y + 30), "+", font=font(26, True), fill=INK, anchor="mm")
    counts = ("1/9", "0/9", "2/9", "0/9") if monster else ("3/9", "2/9", "1/9", "0/9")
    for i, (code, name) in enumerate((("helmet", "Шлем"), ("chestplate", "Нагрудник"), ("gauntlets", "Наручи"),
                                      ("greaves", "Поножи"))):
        y = 615 + i * 92
        d.rounded_rectangle([40, y, 340, y + 76], radius=8, fill=(50, 43, 38), outline=DIM, width=2)
        icon(img, f"ARMOR__{code}", (52, y + 10), 56)
        d.text((122, y + 38), f"{name} · {counts[i]}", font=font(20, True), fill=PARCHMENT, anchor="lm")


def _node_card(img: Image.Image, d: ImageDraw.ImageDraw, monster: bool, accent: tuple) -> None:
    d.rounded_rectangle([1576, 130, 1884, 740], radius=12, fill=(214, 200, 170), outline=accent, width=4)
    if monster:
        title, kind, lines = "Формула Сторожевого Пса", "Формула крови · пассив", [
            "+6 к макс. здоровью;", "карты Ярости стоят", "на 1 здоровья меньше.", "", "Голос +3", "Нужно: образец крови", "Сторожевого Пса (есть)"]
    else:
        title, kind, lines = "Чертёж: Гарпунная пушка", "Чертёж · модули", [
            "Откроет в мастерской", "модуль ствола (3 клетки):", "карта «Гарпун».", "", "Цена: 1 очко", "Нужно: соседний узел", "изучен (есть)"]
    d.text((1730, 170), title, font=font(19, True), fill=INK, anchor="mm")
    d.text((1730, 200), kind, font=font(15), fill=(90, 75, 60), anchor="mm")
    for i, t in enumerate(lines):
        d.text((1600, 250 + i * 32), t, font=font(18), fill=INK, anchor="lm")
    d.rounded_rectangle([1620, 660, 1840, 716], radius=10, fill=accent, outline=INK, width=3)
    d.text((1730, 688), "ИЗУЧИТЬ", font=font(22, True), fill=INK if not monster else PARCHMENT, anchor="mm")


def _special(img: Image.Image, d: ImageDraw.ImageDraw, monster: bool) -> None:
    if not monster:
        d.text((1580, 820), "Чертежи фракций:", font=font(18, True), fill=PARCHMENT, anchor="lm")
        for i, f in enumerate(("lumen", "vigil")):
            icon(img, f"FACTION__{f}", (1580 + i * 70, 850), 56)
        d.text((1720, 878), "найдено 2 / 6", font=font(17, True), fill=PARCHMENT, anchor="lm")
        d.text((1580, 940), "Коллегия Люмен · Орден Бдения", font=font(15), fill=FOG, anchor="lm")
        return
    icon(img, "STAT__voice", (1580, 800), 40)
    d.text((1628, 812), "Голос 9", font=font(20, True), fill=PARCHMENT, anchor="lm")
    d.text((1628, 834), "стадии 19 / 29 / 39 (10/20/30 + 3 × Воля)", font=font(12), fill=FOG, anchor="lm")
    d.rectangle([1580, 852, 1880, 868], fill=(30, 26, 24))
    d.rectangle([1580, 852, 1580 + 300 * 9 // 40, 868], fill=VIOLET)
    for t, label in ((19 / 40, "Шёпот"), (29 / 40, "Голод"), (39 / 40, "Зверь")):
        x = 1580 + 300 * t
        d.line([(x, 846), (x, 874)], fill=PARCHMENT, width=2)
        d.text((x, 888), label, font=font(13), fill=FOG, anchor="rm" if t > 0.9 else "mm")
    d.text((1580, 920), "Образцы крови:", font=font(16, True), fill=PARCHMENT, anchor="lm")
    d.rounded_rectangle([1576, 932, 1884, 998], radius=6, fill=(190, 180, 165))
    for i, (c, label) in enumerate((("VIGIL_HOUND", "Пёс ×2 чист."), ("GUTTER_CHOIR", "Хор ×1"),
                                    ("LAMPLIGHTER", "Фонарщик ×1"))):
        art(img, ROOT / "art" / "monsters" / f"{c}__silhouette__leaflet.webp", (1580 + i * 100, 934, 1660 + i * 100, 980))
        d.text((1620 + i * 100, 990), label, font=font(11, True), fill=INK, anchor="mm")


def _skill_legend(d: ImageDraw.ImageDraw, accent: tuple, monster: bool) -> None:
    x = 410
    for kind, label in (("passive", "пассив"), ("blueprint", "чертёж"), ("socket", "гнездо"), ("key", "ключевой")):
        _node(d, (x + 20, 1040), kind, True, False, accent, False)
        d.text((x + 62, 1040), label, font=font(16), fill=PARCHMENT, anchor="lm")
        x += 160
    d.ellipse([x + 4, 1024, x + 36, 1056], outline=(240, 200, 110), width=4)
    d.text((x + 46, 1040), "можно купить", font=font(16), fill=PARCHMENT, anchor="lm")
    if monster:
        d.ellipse([x + 190, 1034, x + 202, 1046], fill=BLOOD)
        d.text((x + 210, 1040), "нужен образец", font=font(16), fill=PARCHMENT, anchor="lm")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    workshop().save(OUT / "workshop_layout.png")
    skills(False).save(OUT / "skills_mechanic_layout.png")
    skills(True).save(OUT / "skills_monster_layout.png")
    print("written ->", OUT)


if __name__ == "__main__":
    main()
