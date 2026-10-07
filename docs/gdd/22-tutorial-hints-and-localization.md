# 22. Tutorial Hints and Localization

> Owner decisions (2026-10-07): **the whole interface is in Russian** (English later through the same
> translation files); the game **teaches itself with hints that dim the screen and light up the place being
> explained**. Sketch: `docs/assets/ui/tutorial_overlay.png` (`python tools/gen_ui_sketches.py`).

## 22.1 How a hint looks

| Element | Rule |
|---|---|
| Dimming | The whole screen under a 70 % black veil |
| Cut-out | A rounded hole in the veil around the explained element (+12 px margin); the element is fully lit |
| Frame | A brass outline around the hole, slowly pulsing (alpha 0.6–1.0, 1.2 s) |
| Bubble | Parchment card with a pointer towards the hole; title (blood red), 1–3 sentences, step counter «2 / 9» |
| Buttons | «Далее» (brass) and «Пропустить обучение»; on "do it" steps «Далее» is hidden until the player does the action; if the action is impossible or 20 s pass, «Пропустить шаг» appears |
| Input | Clicks outside the hole are blocked; inside the hole the game works normally |
| Placement | The bubble goes above / below / beside the hole, whichever side has room; never covers the hole |

## 22.2 When hints appear

Hints come in **sequences**, each fired once by a trigger. Progress lives in `user://profile.cfg` (not in the run
save), so a new run does not repeat them. Settings: «Подсказки: вкл/выкл», «Сбросить обучение».

| Sequence | Trigger | Steps |
|---|---|---|
| `district_intro` | First time on the district map | 6 |
| `combat_intro` | First fight | 9 |
| `equipment_intro` | First time on the equipment screen | 5 |
| `first_part_broken` | A body part breaks for the first time | 1 |
| `first_panic` | Sanity hits 0 for the first time | 1 |
| `first_no_ammo` | Ammo reaches 0 for the first time | 1 |
| `first_rent` | The day before the first rent | 1 |
| `first_rumor` | First rumor pinned on Bonfire Square (Phase 3) | 3 |

## 22.3 Step texts (Russian drafts)

`do` = the step waits for the action instead of «Далее».

**district_intro**

| # | Highlight | Title | Text |
|---|---|---|---|
| 1 | whole map | Серые Часовни | Трущобы на краю платформы. Здесь вы живёте и охотитесь, пока остальной город закрыт. |
| 2 | map (drag) | Осмотритесь | Зажмите левую кнопку мыши и тяните карту, чтобы увидеть весь район. `do` |
| 3 | hero figurine | Это вы | Нажмите на здание или улицу — охотник пойдёт туда по улицам. |
| 4 | Ash Garret | Дом | Пепельный чердак: здесь вы отдыхаете и платите за комнату. |
| 5 | Tavern | Таверна | В «Фонаре и Крюке» висят заказы на тварей. Сходите туда. `do` |
| 6 | darkened neighbour | Закрыто | Соседние районы пока недоступны. Они откроются по ходу истории. |

**combat_intro**

| # | Highlight | Title | Text |
|---|---|---|---|
| 1 | creature | Тварь | Ваш противник. Над ней — что она сделает в свой ход. |
| 2 | intents | Намерения | Число — сила удара или урон рассудку. Готовьтесь заранее. |
| 3 | hand | Рука | Ваши карты на этот ход. Каждая стоит очки действия — цифра в шестерёнке. |
| 4 | AP lamps | Очки действия | Три лампы — три очка за ход. Горящая лампа — очко, которое ещё есть. |
| 5 | an attack card → creature | Атака | Нажмите карту «Удар», затем тварь. `do` |
| 6 | body part rings | Части тела | Выстрел можно направить в часть тела. Сломанная часть отключает ходы твари. |
| 7 | weapon | Патроны | Выстрелы тратят патроны. Карта «Перезарядка» возвращает их. |
| 8 | hunter vials | Здоровье и рассудок | Красный флакон — здоровье, фиолетовый — рассудок. Без рассудка придёт паника. |
| 9 | end turn lever | Конец хода | Когда сделали всё, что хотели, — потяните рычаг. `do` |

**equipment_intro**

| # | Highlight | Title | Text |
|---|---|---|---|
| 1 | weapon grid | Ружьё | Модули ставятся в ячейки своих секций: приклад, рама, магазин, прицел, ствол. |
| 2 | cell legend | Ячейки | Модуль встаёт только на ячейки своего типа: шестерня, искра или кровь. |
| 3 | spare list | Запасные модули | Выберите модуль, правой кнопкой поверните, нажмите ячейку. `do` |
| 4 | fight deck | Колода | Снаряжение и есть колода: каждый модуль добавляет карты или усиливает их. |
| 5 | armor sockets | Броня | В гнёзда брони ставятся механизмы — ещё карты и бонусы. |

## 22.4 Tutorial — implementation

| Part | Where |
|---|---|
| Sequences as data: `{id, trigger, steps: [{anchor, title_key, text_key, do: event?}]}` | `data/tutorial/*.json` + validator (anchors known, keys exist) |
| Anchors: screens register nodes by id (`hand`, `ap`, `intents`, `end_turn`, `landmark:ash_garret`…). The hole follows its anchor every frame, so anchors on the dragged district map stay correct; a map anchor first scrolls the camera to it | `ui/tutorial/tutorial_anchors.gd` |
| Overlay: veil with a shader cut-out, pulsing frame, bubble placement, input blocking | `ui/tutorial/tutorial_overlay.gd` (CanvasLayer) |
| Runner: listens to EventBus (`tutorial_trigger`, actions for `do` steps), saves progress | `autoload/Tutorial.gd` |
| Profile (seen sequences, hints on/off) | `core/state/profile_state.gd` → `user://profile.cfg` |
| Tests: each sequence plays to the end with fake anchors; skip marks it seen | `tests/test_tutorial.gd` |

## 22.5 Localization

- **Engine:** Godot `TranslationServer` with a CSV table `locale/strings.csv` (columns `keys,ru,en`); Godot builds
  `.translation` files on import. Locale `ru` is the default; `en` is filled later (Phase 10).
- **UI strings:** never written in scenes. `tr("ui.combat.end_turn")` → «Конец хода».
- **Content:** names and descriptions from data use keys by id: `card.strike.name`, `monster.vigil_hound.name`,
  `module.brass_scope.name`, `district.GREY.name`, `landmark.ash_garret.name`… JSON keeps ids and numbers only;
  the English names move to the `en` column.
- **Effect text** (`EffectText`) is built from templates in the same table with numbers and Russian plural forms:
  `effect.draw` = «Возьмите {n} {n:карту|карты|карт}». A tiny formatter (`core/content/loc.gd`) fills `{n}` and picks
  the plural form (1 карту, 2 карты, 5 карт; 21 карту).
- **Checks:** a test fails if any key used by data or scenes has no `ru` text, or a `ru` text has unknown placeholders.
- **EffectText migration:** its English sentences become table templates; a test renders every effect for n = 0…30
  and checks the Russian plural form (1, 2–4, 5–20, 21, 22…).
- **EffectText migration:** its English sentences become table templates; a test renders every effect for n = 0…30
  and checks the Russian plural form (1, 2–4, 5–20, 21, 22…).
- **Font:** bundle a serif font with Cyrillic (e.g. *PT Serif* or *Old Standard TT*, OFL) instead of relying on
  system fonts, so exported builds look the same on every PC.
- **Comments, GDD, prompts and ids stay in English** (CLAUDE.md).

## 22.6 Glossary (Russian names of game terms)

| English | Русский | English | Русский |
|---|---|---|---|
| AP (action points) | ОД (очки действия) | Sanity | Рассудок |
| HP | Здоровье | Block | Защита |
| Bleed | Кровотечение | Exposed | Уязвимость |
| Weak | Слабость | Dodge | Уклонение |
| Panic | Паника | Enraged | Ярость |
| Ammo | Патроны | Reload | Перезарядка |
| Draw / Discard / Exhaust pile | Добор / Сброс / Изгнание | End turn | Конец хода |
| Intent | Намерение | Body part | Часть тела |
| Contract | Заказ | Rumor | Слух |
| Hunt | Охота | Capture | Поимка |
| Module / Mechanism | Модуль / Механизм | Cell: gear, spark, blood | Ячейка: шестерня, искра, кровь |
| Stock, frame, magazine, sight, barrel | Приклад, рама, магазин, прицел, ствол | Equipment | Снаряжение |
| Rank A / P / D / S | Ранг A / P / D / S | Trophy | Трофей |

| Card | Русский | Creature | Русский |
|---|---|---|---|
| Strike | Удар | Gutter Choir | Сточный Хор |
| Guard | Защита | Moth Matron | Матрона Моли |
| Shot | Выстрел | The Lamplighter | Фонарщик |
| Reload | Перезарядка | Rust Mantis | Ржавый Богомол |
| Read the Beast | Прочесть зверя | Mourning Bride | Скорбящая Невеста |
| Sidestep | Уход в сторону | Vigil Hound | Сторожевой Пёс |
| Harpoon Shot / Shock Harpoon | Гарпун / Шоковый гарпун | Clay Saint | Глиняный Святой |
| Flash / Smoke Screen | Вспышка / Дымовая завеса | Burrow Wyrm | Роющий Змей |
| Serrated Edge / Bayonet Thrust | Зазубренный край / Удар штыком | | |
| Gout of Flame / Overcharge | Струя пламени / Перегрузка | | |
| Iron Net / Tonic of Morrell | Железная сеть / Тоник Моррелла | | |
| Hound's Rage / Panic / Dread | Ярость гончей / Паника / Ужас | | |

## 22.7 Implementation order

1. Localization first (every later screen is written in Russian from the start): table, `tr()` in all scenes,
   content keys, `EffectText` templates, font, checks.
2. Tutorial system (overlay + runner + profile) with `combat_intro` and `equipment_intro`.
3. `district_intro` arrives together with the district map (GDD §20).
