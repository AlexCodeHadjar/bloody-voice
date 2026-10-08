# Bloody Voice — карта проекта

Сюжетная игра про охотника на монстров с элементами рогалика. Godot 4.7, GDScript.
Владелец пишет по-русски и сам решает по механике (спрашивать вариантами). Дизайн — `docs/gdd/`
(оглавление `README.md`), порядок работ — `docs/gdd/18-development-roadmap.md`. Репозиторий: github.com/AlexCodeHadjar/bloody-voice (main).

**Документы и заметки — только Markdown (`.md` в `docs/`).** С `.docx` не работать: не создавать, не читать,
не править; просят «ворд» — делать `.md` и сказать об этом.

## Рабочий цикл (обязательно)

1. Работа → `tools/check_all.sh` зелёный (скилл `bv-check`).
2. **Критик.** Отдать работу субагенту `critic` (код, данные, тесты, документация); если менялись механика,
   контент, GDD, экран или арт — ещё и `design-critic` (**сейчас выключен владельцем** — не звать, пока он не скажет включить). В запросе: задача владельца, что сделано, файлы.
   Оценка < 7 или `REWORK` → исправить `MUST FIX` и отправить снова — тому же агенту (SendMessage) и **только
   список исправлений** (до 3 кругов; дальше — отчитаться владельцу с оценкой и причиной).
   Вопросы из `QUESTIONS FOR THE OWNER` — владельцу, не решать за него.
   В отчёте владельцу — итоговые оценки критиков.
3. **CLAUDE.md** — обновить в том же коммите: убрать устаревшее, добавить новое одной строкой. Держать коротким
   (≈ 80 строк): только правила и карта; процедуры — в скиллах `.claude/skills/`, не дублировать.
4. Коммит → push в `main`.

## Экономия контекста

Общие правила (git diff, git log, чтение частями) — в `~/.claude/CLAUDE.md`. Здесь только своё:
- Критикам — задача, «что сделано» коротким списком, файлы и `git diff --stat`; код не пересказывать (diff смотрят сами).

## Скиллы проекта

`bv-check` проверка · `bv-content` данные (карты, твари, эффекты) · `bv-mechanic` чек-лист новой механики ·
`bv-art` арт и импорт · `bv-balance` бот и баланс · `bv-docs` документы и заметки в Markdown.

## Правила кода (GDD §19)

- Слои: `data/` → `core/content` (defs, валидатор) → `core/rules`, `core/generation` → `core/state` →
  `autoload/GameState` → `scenes/`. Правила — `class_name` + `static func`, без узлов и глобалов, меняют
  переданное состояние и возвращают отчёт. Сигналы шлёт только `GameState`; экраны не пишут в `RunState`.
- Числа — `data/balance.json`; контент — JSON через `DefReader`/`ErrorLog`; ошибка данных = игра не стартует.
- Строгие типы (`untyped_declaration` = ошибка), у переменных цикла тоже. `:=` не выводит тип из Variant.
- Файл ≤ 400 строк, функция ≤ 40. Без тяжёлой логики в `_process`. Случайность — только `SeededRng`/`Rng.stream`.
- Сейвы: `RunState.SAVE_VERSION` + `SaveMigrations`; id из сейвов не переименовывать.
- Комментарии, GDD, промты и id — по-английски; заметки для владельца — можно по-русски.
- **Интерфейс игры — на русском** через ключи перевода (`tr()`, `locale/strings.csv`, GDD §22); строк в сценах не писать
  (вводится в фазе 2b; существующие сцены ещё на английских строках — переводить при первой правке).

## Где что

| Область | Файлы |
|---|---|
| Контент | `core/content/` (`content_loader`, `content_validator`, `def_reader`, `effect_schema`, `effect_text` — текст хода из эффектов, `defs/`); `data/` |
| Состояние | `core/state/run_state.gd` (день, деньги, район, `CityState`, `LoadoutState`; `SAVE_VERSION` 2), `save_migrations.gd`; бой — `core/state/combat/` |
| Время, город | `core/rules/time/` (календарь, конец дня, аренда); `core/rules/city/` (попадание по карте, состояния районов) |
| Бой | `core/rules/combat/` (`combat_rules` поток, `effect_applier`, `damage_rules`, `enemy_rules`, `deck_rules`, `status_rules`, `capture_rules`, `gear_effect_rules` — бонусы снаряжения) |
| Снаряжение (GDD §5) | состояние `core/state/loadout_state.gd`; правила `core/rules/gear/` (`weapon_grid_rules` ячейки/поворот/связки, `armor_rules` гнёзда, `deck_builder` колода и бонусы → `CombatSetup`); defs `weapon_def`, `module_def`, `gear_misc_defs`, `gear_mods.gd`, `gear_validator.gd`; данные `data/gear/`, старт — `balance.json/gear`; экран `scenes/equipment/` |
| Генерация | `core/generation/` (`seeded_rng`, `encounter_rules` — заглушка до слухов) |
| Разработка | `core/dev/combat_bot.gd`, `dev_shots.gd` (`--shots`); `tests/` (`run_tests.gd`, `bot/autoplay.gd`) |
| Автозагрузки | `EventBus`, `ContentDB`, `Rng`, `SaveService`, `GameState` (фасад-команды), `DevShots` |
| Экраны | `scenes/boot`, `menu`, `city_map` (карта, карточка района), `equipment` (оружие, броня), `combat` (бой) |
| UI | `ui/theme/palette.gd`, `ui_kit.gd`, `icons.gd` (иконки по набору и id) |
| Арт | `assets/` и `assets/png/` исходники (не в git) → `tools/import_art.py` → `art/` (твари, модули, иконки); контуры районов `data/city/map_regions.json` |
| Иконки | каталог `data/ui/icons.json` |
| Документы | `docs/gdd/` (GDD по разделам; §20 район, §21 бой v2, §22 обучение и русский, §23 мастерская и ветки), `docs/art-prompts/` (генерируется `tools/gen_art_prompts.py`, кроме `district-grey-chapels.md`, `combat-ui.md`, `workshop-and-skills-ui.md`), `docs/assets/` (эскизы: `map/`, `districts/GREY/`, `ui/`) |
| Инструменты | `tools/` (`check_all.sh`, `import_art.py`, `tune_monsters.py`, `gen_art_prompts.py`, `gen_art_templates.py`, `gen_city_sketch.py`, `gen_district_sketch.py` + `district_layout_grey.py`, `district_detail.py`, `district_sections.py` — карта района, `gen_ui_sketches.py`, `gen_screen_sketches.py` — эскизы экранов) |
| Агенты | `.claude/agents/critic.md`, `design-critic.md` |
