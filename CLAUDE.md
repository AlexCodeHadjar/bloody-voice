# Bloody Voice — карта проекта

Сюжетная игра про охотника на монстров с элементами рогалика. Godot 4.7, GDScript.
Владелец пишет по-русски и сам решает по механике (спрашивать вариантами). Дизайн — `docs/gdd/`
(оглавление `README.md`), порядок работ — `docs/gdd/18-development-roadmap.md`. Репозиторий: github.com/AlexCodeHadjar/bloody-voice (main).

**Документы и заметки — только Markdown (`.md` в `docs/`).** С `.docx` не работать: не создавать, не читать,
не править; просят «ворд» — делать `.md` и сказать об этом.

## Рабочий цикл (обязательно)

1. Работа → `python tools/gen_reference.py`. **Тесты и `tools/check_all.sh` не прогонять** (владелец, 2026-10-12: пока
   не нужны) — только по его просьбе (скилл `bv-check`).
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
- **Картинки не открывать без прямой просьбы владельца.** Для проверки сначала текст (страница, лог, данные, тесты);
  скриншот — только если без него никак, и уменьшенный.
- **Чистка от лишнего (владелец, 2026-10-12).** В конце каждого шага удалять то, что тратит токены, но игре не нужно:
  промты к уже полученному арту, инструменты и планы законченных работ, справочные выгрузки (manifest, html, csv
  и т. п.), устаревшие куски GDD; ссылки на удалённое убрать. Такое не заводить. Картинки, ассеты, код, данные,
  GDD и `docs/reference/` не трогать; если сомнения — спросить списком.
- Критикам — задача, «что сделано» коротким списком, файлы и `git diff --stat`; код не пересказывать (diff смотрят сами).
- **Справочник — сначала он, потом поиск:** `docs/reference/code.md` (все скрипты: класс, назначение, функции),
  `data.md` (файлы данных и id, ключи перевода), `assets.md` (арт и звук в игре, чего не прислали) — после правок
  обновлять `python tools/gen_reference.py`; `decisions.md` — решения владельца
  и открытые вопросы, **обновлять вручную**.

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
- **Интерфейс игры — на русском**: любой текст только через `Loc.t("ключ")` (`core/content/loc.gd`, таблица `locale/strings.csv`,
  GDD §22.5); названия из данных переводит `ContentLoc` при загрузке; новый контент → `python tools/gen_locale.py`, вписать ru.

## Где что

| Область | Файлы |
|---|---|
| Контент | `core/content/` (`content_loader`, `content_validator`, `def_reader`, `effect_schema`, `effect_text` — текст хода из эффектов, `loc` + `content_loc` — русский текст, `defs/`); `data/` |
| Перевод | `locale/strings.csv` (keys, ru, en; `.translation` создаёт импорт) · `tools/gen_locale.py` · тест `tests/test_locale.gd` |
| Состояние | `core/state/run_state.gd` (день, деньги, район, `hero_node`, `open_districts`, `CityState`, `LoadoutState`; `SAVE_VERSION` 3), `save_migrations.gd`; бой — `core/state/combat/` |
| Время, город | `core/rules/time/` (календарь, конец дня, аренда); `core/rules/city/` (попадание по карте, состояния районов, `district_map_rules` — путь по улицам района) |
| Район (GDD §20) | данные `data/city/district_maps/GREY.json` (улицы, места, зоны, звук; размечено по итоговой карте) и `data/city/district_life/GREY.json` (жители, сценки, декор); defs `district_map_def`, `district_life_def`; экран `scenes/district_map/` (камера, герой, карточка места, F3 — разметка; `life/` — жители); проверка разметки `tools/check_district_map.py` |
| Бой | `core/rules/combat/` (`combat_rules` поток, `effect_applier`, `damage_rules`, `enemy_rules`, `deck_rules`, `status_rules`, `capture_rules`, `gear_effect_rules` — бонусы снаряжения) |
| Снаряжение (GDD §5) | состояние `core/state/loadout_state.gd`; правила `core/rules/gear/` (`weapon_grid_rules` ячейки/поворот/связки, `armor_rules` гнёзда, `deck_builder` колода и бонусы → `CombatSetup`); defs `weapon_def`, `module_def`, `gear_misc_defs`, `gear_mods.gd`, `gear_validator.gd`; данные `data/gear/`, старт — `balance.json/gear`; экран `scenes/equipment/` |
| Генерация | `core/generation/` (`seeded_rng`, `encounter_rules` — заглушка до слухов) |
| Разработка | `core/dev/combat_bot.gd`, `dev_shots.gd` (`--shots`); `tests/` (`run_tests.gd`, `bot/autoplay.gd`) |
| Автозагрузки | `EventBus`, `ContentDB`, `Rng`, `SaveService`, `GameState` (фасад-команды), `Sound` (звук, GDD §24), `Profile` (настройки игрока, `user://profile.cfg`), `Tutorial` (подсказки), `DevShots` |
| Обучение (GDD §22) | данные `data/tutorial/sequences.json`; `ui/tutorial/` (`tutorial_flow` логика, `tutorial_anchors` — экраны регистрируют подсвечиваемое, `tutorial_overlay`); `Tutorial.trigger()/action()` из экранов; настройки `scenes/settings/settings_panel.gd` |
| Звук | `audio/` (из набора владельца: `tools/import_audio.py`), что где звучит — `data/audio/sounds.json` (`AudioDef`, `AudioValidator`); экраны — `UiKit.sound()/screen_sound()/monster_sound()`, бой — `scenes/combat/combat_sounds.gd`; титры `docs/credits.md` |
| Экраны | `scenes/boot`, `menu`, `district_map` (главный экран: район), `city_map` (карта города, закрытые районы), `equipment` (оружие, броня), `combat` (бой) |
| UI | `ui/theme/palette.gd`, `ui_kit.gd` (тема, шрифты `ui/fonts/` — PT Serif, заголовки Old Standard TT), `icons.gd` (иконки по набору и id) |
| Арт | `assets/` и `assets/png/` исходники (не в git) → `tools/import_art.py` → `art/` (твари, модули, иконки; `TEX__*` — бесшовные текстуры; листы жителей `LIFE__*__sheet` → `art/ui/life/` через `tools/life_sprites.py`); контуры районов `data/city/map_regions.json` |
| Иконки | каталог `data/ui/icons.json` |
| Документы | `docs/gdd/` (GDD по разделам; §20 район, §21 бой v2, §22 обучение и русский, §23 мастерская и ветки, §24 звук), `docs/art-prompts/` (арт, которого ещё нет: `art-backlog.md`, блоки стиля `style-blocks.md`; `map-life-people.md` — жители и их сюжеты), `docs/assets/` (эскизы-картинки) |
| Инструменты | `tools/` (`check_all.sh`, `import_art.py` (+ `life_sprites.py`; готовая карта района `assets/district_maps/*__map.png` → `art/city/district_maps/`), `import_audio.py`, `gen_locale.py`, `gen_reference.py`, `tune_monsters.py`, `check_map_regions.py`, `check_district_map.py`) |
| Агенты | `.claude/agents/critic.md`, `design-critic.md` |
