---
name: bv-art
description: Арт-пайплайн Bloody Voice — импорт картинок от владельца из assets/ в игру, правила имён файлов, подгонка модулей под клетки, нарезка наборов иконок, контуры районов на карте, шаблоны и промты для ChatGPT. Используй, когда владелец «загрузил материалы/арт/картинки», просит промты для генерации, новые иконки, силуэты тварей, модули, или арт не появился в игре.
---

# Арт

## Куда класть и как называть

Исходники — `assets/<папка>/` (не в git, Godot их не видит). Имя: `<CODE>__<kind>__<state>.png`
(CODE заглавными, остальное строчными).

| Папка | Пример | Попадает в |
|---|---|---|
| `districts` | `NORDHAL__tile__normal.png`, `NORDHAL__scene__flooded.png` | `art/city/districts/` |
| `map` | `HALLOWDEEP__map__normal.png` | `art/city/map/` |
| `ui` | `CONTRACT__tablet.png` | `art/ui/` |
| `modules` | `CAPACITOR_BANK__module__normal.png` | `art/gear/modules/` — подгоняется под фигуру, 256 px на клетку |
| `monsters` | `GUTTER_CHOIR__combat__normal.png`, `__phase2`, `__silhouette__leaflet`, `__silhouette__cracked` | `art/monsters/` |
| `icons` | `STATUS__sheet.png` (весь набор одной картинкой) | `art/ui/icons/STATUS__<id>.webp` |

## Импорт

```bash
python tools/import_art.py          # только изменённое; --force — всё заново
tools/check_all.sh                  # импорт в Godot + проверка, что валидатор видит арт
```

Ошибки импорта говорят, что не так с именем или какого id нет в данных. Иконки режутся по сетке `grid`
из `data/ui/icons.json`: кусок уходит в ячейку своего центра, соринки отбрасываются. Если иконка «потерялась» —
посмотри картинку: возможно, ChatGPT нарушил раскладку; попроси перегенерировать набор целиком.

## Районы на карте

Контуры — `data/city/map_regions.json` (порядок = приоритет попадания, `anchor` — где стоит фигурка).
Новая карта или правка → `python tools/check_map_regions.py "<scratchpad>/regions.png"` и посмотри наложение.
Тест `tests/test_map_regions.gd` проверяет контрольные точки — обнови их, если карта изменилась.

## Промты для ChatGPT

- Город, районы, состояния районов, интерфейс — `docs/gdd/16-art-direction-and-generation-prompts.md`.
- Модули, твари, иконки — `docs/art-prompts/*.md`, генерируются из данных: `python tools/gen_art_prompts.py`.
  Шаблоны к ним: `python tools/gen_art_templates.py` → `docs/assets/templates/`.
- Схема города: `python tools/gen_city_sketch.py` → `docs/assets/map/`.
- Новые иконки или модули добавляй сначала в данные (`data/ui/icons.json`, `data/gear/modules.json`),
  потом перегенерируй промты — так промты и нарезка не разойдутся.
