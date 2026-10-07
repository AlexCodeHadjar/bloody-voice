# Bloody Voice — карта проекта для Claude

Сюжетная игра про охотника на монстров с элементами рогалика (Godot 4.7, GDScript). Владелец пишет по-русски,
решения по механике принимает сам. Дизайн — `Bloody Voice - Game Design Document.docx` (собирается из
`tools/gdd/*.js`: `npm install` в `tools/gdd`, затем `node build.js`). Порядок работ — GDD §18 (фазы 0–10).
После каждого шага фазы — тесты зелёные → коммит → push в `main` (github.com/AlexCodeHadjar/bloody-voice, публичный).

## Правила кода (GDD §19)

- Слои: `data/` → `core/content` (defs) → `core/rules`, `core/generation` → `core/state` → `autoload/GameState` → `scenes/`.
  Правила — `class_name` + `static func`, без узлов и глобалов; меняют только переданный им объект состояния и
  возвращают отчёт. Сигналы шлёт только `GameState` (через `EventBus`). Экраны **не** пишут в `RunState`.
- Новая механика = файл `core/rules/<домен>/<механика>_rules.gd` + тест `tests/test_<механика>.gd` (добавить в
  `SUITES` в `tests/run_tests.gd`) + проверки в `content_validator.gd`, если есть данные.
- Все числа — в `data/balance.json` (`BalanceDef`). Контент — JSON, читается через `DefReader` с `ErrorLog`.
- Строгая типизация: `untyped_declaration` = ошибка. Переменные цикла тоже с типом (`for x: T in`).
  `:=` не выводит тип из Variant/Dictionary — писать `var x: T = …`.
- Файл ≤ 400 строк, функция ≤ 40. Никакой тяжёлой логики в `_process`.
- Случайность только из `SeededRng.make_stream(seed, система, день)` / `Rng.stream(...)`.
- Сохранения: `RunState.SAVE_VERSION` + `SaveMigrations`. Не переименовывать id, которые попадают в сейвы.
- Комментарии и тексты игры — по-английски.

## Арт

- Исходники от владельца — `assets/<districts|map|ui>/` (не в git, Godot их не видит). Имена `<CODE>__<kind>__<state>`.
- `python tools/import_art.py` → `art/` (webp). Лист иконок ресурсов режется на `art/ui/icons/RESOURCE__<id>.webp`.
- Районы на карте-картинке — полигоны `data/city/map_regions.json` (порядок = приоритет попадания, анкер — где
  стоит фигурка). Проверка: `python tools/check_map_regions.py <out.png>`.
- Схема города для промтов: `python tools/gen_city_sketch.py` → `docs/assets/map/`.

## Команды

```bash
G="/d/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import
"$G" --headless --path . -s res://tests/run_tests.gd            # -- --only=calendar
"$G" --path . --resolution 1920x1080 -- --shots=<абс. папка>    # автоснимки (core/dev/dev_shots.gd)
```

## Где что

| Область | Файлы |
|---|---|
| Контент | `core/content/content_loader.gd`, `content_validator.gd`, `def_reader.gd`, `defs/*.gd`; данные `data/` |
| Состояние | `core/state/run_state.gd` (день, деньги, район героя, `CityState`), `place_state.gd`, `save_migrations.gd` |
| Правила | `core/rules/time/calendar_rules.gd`, `day_rules.gd` (конец дня, аренда); `core/rules/city/map_region_rules.gd`, `district_state_rules.gd` (состояния районов GDD §14) |
| Автозагрузки | `EventBus`, `ContentDB`, `Rng`, `SaveService`, `GameState` (фасад-команды), `DevShots` |
| Экраны | `scenes/boot`, `scenes/menu/main_menu`, `scenes/city_map/` (`map_view.gd`, `district_panel.gd`) |
| UI | `ui/theme/palette.gd`, `ui_kit.gd` |
