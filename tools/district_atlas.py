"""Atlas of the Grey Chapels map for the owner: the plan with zones in strong colours, borders by type,
special objects, a close-up of every zone and every landmark, all gathered in one Markdown file.
Writes docs/art-prompts/grey-chapels-map/atlas.md and atlas/*.png. Called by tools/gen_district_sketch.py.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

import gen_district_sketch as g

ZONE_COLOURS = {"ash_quarter": (235, 140, 40), "shanty_roofs": (230, 210, 60), "chapel_close": (150, 100, 220),
                "fog_hollow": (60, 190, 220), "lower_yards": (170, 110, 60), "edge_walk": (60, 110, 230)}
ZONE_TEXT = {
    "ash_quarter": "Сердце жизни охотника: дом, таверна, мастерская, лавка, рынок. Тесные ряды закопчённых доходных домов "
                   "в 2–3 этажа, бельё между окнами, костры в бочках. Бедно, но живо.",
    "shanty_roofs": "Хибары, построенные прямо на крышах старых домов; между ними верёвочные мосты и лестницы, голубятни, "
                    "лес труб. Ветрено и шатко. Здесь видят тени на крышах.",
    "chapel_close": "Разрушенная Старая Серая Часовня и её обнесённый стеной двор: поваленные святые, серые свечи, меловые "
                    "знаки культа. Свято и неправильно. Тайный центр Серого Причастия.",
    "fog_hollow": "Провал, где платформа просела: узкий овраг на два этажа ниже улиц, в нём лежит туман, как вода. "
                  "Затопленные подвалы. Над ним — Мост Свечей. Холодно и тихо.",
    "lower_yards": "Дворы, сараи и лачуги вдоль акведука до южного края; кладбище бедняков, лазарет, трамвайное депо. "
                   "Заброшенно и голодно.",
    "edge_walk": "Узкая дорожка с перилами у подножия Кольцевой стены, фонари на цепях, в тени стены. Головокружительно.",
}
LANDMARK_RU = {
    "old_grey_chapel": "Сюжетный центр Серого Причастия, первый сюжетный заказ",
    "silent_belfry": "Высокая колокольня без колокола: смотровая точка, слухи рядом",
    "north_gate": "Выход в Нордхал — закрыт в начале",
    "ash_market": "Ежедневная торговля, еда, сплетни",
    "rag_and_bone": "ЛАВКА: оружие, модули, расходники",
    "lantern_and_hook": "ТАВЕРНА: доска заказов, подработка, сплетни",
    "ash_garret": "ДОМ: отдых, аренда, тайник; отсюда начинается игра",
    "rusty_cog": "МАСТЕРСКАЯ: изготовление и установка модулей",
    "bonfire_square": "Столб листовок — здесь вывешивают слухи",
    "candle_bridge": "Каменный мост над логом, свечи по парапетам",
    "fog_cellars": "Ночные охоты, туманные твари, тайные комнаты культа",
    "crypt_scriptorium": "БИБЛИОТЕКА: изучение тварей, старые книги",
    "god_in_the_wall": "Святилище запретной веры в Кольцевой стене",
    "edge_walk": "Дорожка у стены, редкие события",
    "old_aqueduct": "Кирпичный акведук на арках, по верху можно ходить",
    "ash_sisters": "Лечение здоровья и рассудка за деньги",
    "nameless_yard": "Кладбище бедняков: ихор, заказы на гулей",
    "broken_hoist": "Запечатанный спуск в нижние трущобы (глава II)",
    "south_passage": "Выход к Подъёмникам Дипрайт — закрыт",
    "west_crossing": "Переезд к Люмену и Рынку Роуэн — закрыт",
    "tram_depot": "Конец трамвайной линии; позже — путь в другие районы",
}
BORDER_COLOURS = {"street": (245, 245, 245), "rail": (230, 50, 50), "viaduct": (240, 150, 40), "ringwall": (60, 110, 230)}


def _base(size: tuple[int, int]) -> Image.Image:
    img = g.draw_plan(size, labels=False)
    img = ImageEnhance.Color(img).enhance(0.25)
    return ImageEnhance.Brightness(img).enhance(1.1)


def _legend(img: Image.Image, rows: list[tuple[tuple, str]], title: str) -> Image.Image:
    out = Image.new("RGB", (img.width + 820, img.height), (30, 26, 24))
    out.paste(img, (0, 0))
    d = ImageDraw.Draw(out)
    d.text((img.width + 30, 30), title, font=g.font(30, True), fill=(217, 181, 106))
    for i, (colour, text) in enumerate(rows):
        y = 100 + i * 64
        d.rectangle([img.width + 30, y, img.width + 80, y + 40], fill=colour, outline=(236, 228, 210), width=2)
        d.text((img.width + 96, y + 20), text, font=g.font(22, True), fill=(236, 228, 210), anchor="lm")
    return out


def zones_map(size: tuple[int, int]) -> Image.Image:
    img = _base(size).convert("RGBA")
    over = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    for zid, _en, _ru, poly, _tint in g.ZONES:
        c = ZONE_COLOURS[zid]
        d.polygon([g.sk(p) for p in poly], fill=c + (110,), outline=c + (255,), width=6)
    img.alpha_composite(over)
    return _legend(img.convert("RGB"), [(ZONE_COLOURS[z], ru) for z, _en, ru, _p, _t in g.ZONES], "Зоны района")


def borders_map(size: tuple[int, int]) -> Image.Image:
    img = _base(size)
    d = ImageDraw.Draw(img)
    for a, b, kind, _ru, _en in g.BORDER:
        if kind == "ringwall":
            top, bottom = g.sk(g.CONTOUR[a])[1], g.sk(g.CONTOUR[b])[1]
            d.line([p for p in g._wall_lines()[0] if top <= p[1] <= bottom], fill=BORDER_COLOURS[kind], width=22)
        else:
            d.line([g.sk(g.CONTOUR[i % len(g.CONTOUR)]) for i in range(a, b + 1)], fill=BORDER_COLOURS[kind], width=22)
    rows = [(BORDER_COLOURS[k], ru) for _a, _b, k, ru, _en in g.BORDER]
    return _legend(img, rows + [((90, 90, 90), "Стены между районами НЕТ")], "Границы района")


def objects_map(size: tuple[int, int]) -> Image.Image:
    img = _base(size).convert("RGBA")
    over = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    d.polygon([g.sk(p) for p in g.GULLY], fill=(60, 190, 220, 150), outline=(60, 190, 220, 255), width=5)
    d.line([g.sk(g.NODES[g.BRIDGE[0]]), g.sk(g.NODES[g.BRIDGE[1]])], fill=(250, 220, 60, 255), width=26)
    d.line([g.sk(g.AQUEDUCT[0]), g.sk(g.AQUEDUCT[1])], fill=(240, 120, 40, 255), width=24)
    for _n, _ru, nodes, w in g.STREETS:
        if w == 0:
            d.line([g.sk(g.NODES[n]) for n in nodes], fill=(90, 200, 90, 255), width=10)
    depot = next(lm for lm in g.LANDMARKS if lm[0] == "tram_depot")
    x, y = g.sk(depot[4])
    d.ellipse([x - 70, y - 60, x + 70, y + 60], outline=(200, 80, 220, 255), width=8)
    img.alpha_composite(over)
    rows = [((60, 190, 220), "Туманный лог — на 2 этажа ниже"), ((250, 220, 60), "Мост Свечей — на уровне улиц"),
            ((240, 120, 40), "Старый акведук — арки, ~4 этажа"), ((90, 200, 90), "Верёвочные мосты по крышам"),
            ((200, 80, 220), "Трамвайное депо — конец рельсов")]
    return _legend(img.convert("RGB"), rows, "Особые объекты")


def crops(sketch: Image.Image, folder: Path) -> None:
    """A close-up of every zone and every landmark, cut from the labelled sketch."""
    for zid, _en, _ru, poly, _t in g.ZONES:
        pts = [g.sk(p) for p in poly]
        box = (max(0, min(p[0] for p in pts) - 40), max(0, min(p[1] for p in pts) - 40),
               min(1408, max(p[0] for p in pts) + 40), max(p[1] for p in pts) + 40)
        im = sketch.crop(tuple(int(v) for v in box))
        im.thumbnail((760, 760))
        im.save(folder / f"zone_{zid}.png")
    for i, lm in enumerate(g.LANDMARKS, 1):
        x, y = g.sk(lm[4])
        sketch.crop((int(x - 150), int(y - 110), int(x + 150), int(y + 110))).save(folder / f"lm_{i:02d}.png")


def markdown() -> str:
    lines = ["# Атлас района «Серые Часовни»", "",
             "Сгенерирован `tools/gen_district_sketch.py` — руками не править. Как генерировать карту — [README.md](README.md),",
             "промты — [prompts.md](prompts.md), дизайн — [GDD §20](../../gdd/20-district-view-grey-chapels.md).", "",
             "## 1. Весь район", "", "![sketch](for-owner/sketch.png)", "",
             "## 2. Зоны (цветом)", "", "![zones](atlas/zones.png)", ""]
    for zid, _en, ru, _p, _t in g.ZONES:
        inside = [f"{i}. {lm[2]}" for i, lm in enumerate(g.LANDMARKS, 1) if _zone_of(lm[4]) == zid]
        lines += [f"### {ru}", "", ZONE_TEXT[zid], "", f"Места: {', '.join(inside) if inside else '—'}", "",
                  f"![{zid}](atlas/zone_{zid}.png)", ""]
    lines += ["## 3. Границы — стены между районами нет", "", "![borders](atlas/borders.png)", "",
              "## 4. Особые объекты и высоты", "", "![objects](atlas/objects.png)", "",
              "Разрезы (вид сбоку):", "", "![sections](for-owner/sections.png)", "",
              "## 5. Все места", "", "| № | Место | Что это в игре | Вид на плане |", "|---|---|---|---|"]
    for i, lm in enumerate(g.LANDMARKS, 1):
        lines.append(f"| {i} | **{lm[2]}**<br>{lm[1]} | {LANDMARK_RU[lm[0]]} | ![{i}](atlas/lm_{i:02d}.png) |")
    lines += ["", "## 6. Сетка кусков для генерации", "", "![tiles](for-owner/tiles.png)", "",
              "## 7. Одобренные образцы", "", "Сломанный подъёмник (18) — таким и оставить:", "",
              "![hoist](examples/approved_18_broken_hoist.png)", ""]
    return "\n".join(lines)


def _zone_of(p: tuple[float, float]) -> str:
    for zid, _en, _ru, poly, _t in g.ZONES:
        if g.detail.inside_or_near(poly, p, 0):
            return zid
    return ""


def location() -> Image.Image:
    img = Image.open(g.CITY_MAP).convert("RGB")
    dark = Image.new("RGB", img.size, (12, 10, 10))
    mask = Image.new("L", img.size, 175)
    ImageDraw.Draw(mask).polygon([g.city(p) for p in g.outline_c()], fill=0)
    img = Image.composite(dark, img, mask)
    d = ImageDraw.Draw(img)
    d.line([g.city(p) for p in g.outline_c() + g.outline_c()[:1]], fill=g.BRASS, width=4)
    x0, y0 = g.city(g.FRAME_C)
    x1, y1 = g.city((g.FRAME_C[0] + g.WORLD[0] / g.SCALE, g.FRAME_C[1] + g.WORLD[1] / g.SCALE))
    d.rectangle([x0, y0, x1, y1], outline=(40, 120, 220), width=3)
    d.text((x0 + 8, y0 + 6), "district map frame", font=g.font(18), fill=(40, 120, 220))
    return img


def build() -> None:
    folder = g.OUT / "atlas"
    folder.mkdir(parents=True, exist_ok=True)
    size = (int(g.WORLD[0] * g.SKETCH_SCALE), int(g.WORLD[1] * g.SKETCH_SCALE))
    zones_map(size).save(folder / "zones.png")
    borders_map(size).save(folder / "borders.png")
    objects_map(size).save(folder / "objects.png")
    crops(Image.open(g.OWNER / "sketch.png").convert("RGB"), folder)
    (g.OUT / "atlas.md").write_text(markdown(), encoding="utf-8", newline="\n")
    reference_sheet([]).save(g.GPT / "reference_sheet.png")  # in git: no third-party images
    refs = sorted((g.ROOT / "assets" / "refs").glob("STYLE_ref_*.webp"))
    if refs:  # local only (assets/ is not in git): the same sheet with the owner's style references
        reference_sheet(refs).save(g.ROOT / "assets" / "refs" / "GREY_reference_sheet_full.png")


def reference_sheet(style_refs: list[Path]) -> Image.Image:
    """Everything ChatGPT needs in ONE image, panels marked by letters only (no words to copy):
    P plan, S side views (with their own small A-D), L location in the city, H approved Broken Hoist,
    R1-R3 the owner's style references."""
    sheet = Image.new("RGB", (2400, 1700), (24, 22, 22))
    d = ImageDraw.Draw(sheet)

    def put(path: Path, box: tuple[int, int, int, int], letter: str) -> None:
        if not path.exists():
            return
        im = Image.open(path).convert("RGB")
        im.thumbnail((box[2] - box[0], box[3] - box[1]), Image.LANCZOS)
        x, y = box[0] + (box[2] - box[0] - im.width) // 2, box[1] + (box[3] - box[1] - im.height) // 2
        sheet.paste(im, (x, y))
        w, by = 40 + 30 * len(letter), y + im.height - 64  # bottom-left: clear of the side views' own A-D
        d.rectangle([x, by, x + w, by + 64], fill=(176, 138, 74))
        d.text((x + w / 2, by + 32), letter, font=g.font(44, True), fill=(24, 22, 22), anchor="mm")

    put(g.GPT / "plan_clean.png", (20, 20, 1220, 1680), "P")
    put(g.GPT / "sections_clean.png", (1240, 20, 2380, 680), "S")
    put(g.GPT / "location.png", (1240, 700, 1800, 1180), "L")
    put(g.OUT / "examples" / "approved_18_broken_hoist.png", (1820, 700, 2380, 1180), "H")
    for i, ref in enumerate(style_refs[:3]):
        put(ref, (1240 + i * 383, 1200, 1240 + (i + 1) * 383 - 10, 1680), f"R{i + 1}")
    return sheet
