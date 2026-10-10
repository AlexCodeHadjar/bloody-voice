# Art Prompts — full art backlog (everything else the game will need)

> **Готово (2026-10-10):** части G–Q (93 картинки, +3 наброска R) сгенерированы и импортированы в `art/`; листы иконок `MECHANISM` и
> `SETTINGS` разрезаны (наборы добавлены в `data/ui/icons.json`). Наброски тварей R лежат в `assets/refs/CONCEPT__*` —
> в игру не идут, ждут решения владельца. Q1 (значок) — из `art/ui/WAX__seal.webp`, когда понадобится.

Всё, что ещё понадобится игре из арта, **кроме** уже расписанного:
- [next-art-pack.md](next-art-pack.md) — экран района, обучение, курсоры, меню, фоны боя, текстуры, интерьеры, портреты жителей;
- [remaining-ui-transparent.md](remaining-ui-transparent.md) — мастерская и ветки развития;
- [grey-chapels-map/](grey-chapels-map/README.md) — карта трущоб.

Собрано по GDD: бой (§9, §21), охотник (§4), мастерская (§6), таверна (§7), расследование (§8), поимка и бестиарий
(§10), экономика (§11), события (§15), время (§3). Hand-written; prompts in English, instructions in Russian.

## Порядок

| Часть | Что | Картинок | Когда нужно |
|---|---|---|---|
| **G** | Мелкие детали интерфейса: разделители, уголки, заголовки, подсказки, полосы прокрутки, ползунок, счётчик, всплывашка, клавиша и мышь для обучения, шестерёнка загрузки | 17 | **сейчас** — во всех экранах фазы 2b |
| **H** | Эффекты боя: удар, выстрел, кровь, искры, огонь, ток, дым, вспышка, сеть, страх, лечение, трещина | 13 | **сейчас** — бой v2 (§21: вспышка удара, анимации карт) |
| **I** | Картинки на картах (окно в верхней части карты) | 19 | когда захочешь (до них игра ставит большую иконку типа) |
| **J** | Иконки: механизмы брони, настройки | 2 листа | механизмы — сейчас; настройки — с меню |
| **K** | Расследование: листовка, картинки слухов | 11 | фаза 3 |
| **L** | Экраны итогов: победа, Падение охотника, конец дня, аренда, добыча, новый уровень, стадия Голоса, Реестр | 8 | фазы 3–6 |
| **M** | Портрет охотника по стадиям Голоса | 3 | фаза 6 |
| **N** | Бестиарий, поимка, вскрытие | 5 | фазы 3–6 |
| **O** | Сюжет: окно диалога, табличка имени, заставки глав | 5 | фазы 8–9 |
| **P** | События города | 9 | фаза 7 |
| **Q** | Обложка Steam (значок игры — из готовой печати) | 1 | фаза 10 |
| **R** | Новые твари для Серых Часовен — **только после твоего решения** | 3 наброска | когда решишь |

## Не из ChatGPT (тоже понадобится)

| Что | Откуда |
|---|---|
| **Шрифты с кириллицей** | Готовые бесплатные (лицензия OFL): заголовки — *Ruslan Display* или *Old Standard TT*; текст — *PT Serif* или *Cormorant Garamond*. Выбирает владелец, подключаю я |
| Красная виньетка при низком здоровье, дрожание экрана, затемнение при панике | Кодом (шейдер) |
| Цифры урона, полоски здоровья, выделение карт | Кодом, шрифтом |
| Звуки и музыка | Отдельно (фаза 10), не картинки |
| Состояния районов поверх карты (пожар, затопление, карантин) | Отдельный файл к фазе 7 — по каждому району |

## Как пользоваться

1. **Блоки стиля** — те же, что в [next-art-pack.md](next-art-pack.md) («Как пользоваться»): UI STYLE BLOCK,
   TRANSPARENT BLOCK, SCENE STYLE BLOCK, TEXTURE BLOCK. В каждой части сказано, какие вставлять. Здесь добавлен
   один новый — BLACK BLOCK (для светящихся эффектов).
2. Модель — ChatGPT Images 2.0, режим Thinking; **один чат на часть**.
3. Холст: square 1024×1024, wide 1536×1024, tall 1024×1536 — указан в каждой части или строке.
4. «With X attached» — приложи уже готовую картинку X, чтобы набор был одного вида.
5. Сохрани с точным именем в указанную папку и напиши мне «импортируй арт».

```text
BLACK BLOCK:
Output the effect alone on a pure black background (#000000), nothing else in the image: no ground, no frame,
no other objects. The game adds it on top of the scene with light blending, so everything that is not the effect
must stay pure black. No text, no letters, no numbers.
```

## G. Мелкие детали интерфейса (17) — чат «Small UI»

UI STYLE BLOCK + TRANSPARENT BLOCK. Папка `assets/ui/` (не путать с иконками `UI__*` — те лежат в `assets/icons/`, файлы не пересекаются). Приложи `art/ui/COMBAT__plate.webp`:
«Same brass, rivets and engraved look as the attached plate.»

| # | Файл | Холст | Где в игре | Промт |
|---|---|---|---|---|
| G1 | `UI__divider.png` | wide | Линия между частями окна | A thin horizontal ornamental divider of tarnished brass: a straight line with a small engraved diamond and two short curls in the middle, tapering ends. Across the whole canvas width, very thin, transparent above and below. |
| G2 | `UI__corner.png` | square | Уголки на окнах (игра поворачивает на 4 угла) | An ornate L-shaped corner piece of tarnished brass with a rivet and a small engraved leaf curl, the corner of the L in the top-left of the canvas. |
| G3 | `UI__header_plate.png` | wide | Заголовок окна («Настройки», «Итоги дня»). Растягивается | A horizontal name plate of dark wood with a brass frame and small swallow-tail ends on both sides, empty face for a word. Across the canvas width, about one fifth of the canvas tall. Uniform border so it can be stretched. |
| G4 | `UI__tooltip_dark.png` | wide | Подсказки в бою и на снаряжении (карта, статус, модуль). Растягивается | A small horizontal card of blackened iron with a thin dull brass edge and tiny corner rivets, dark and flat inside for light text. Across the canvas width, about one third of the canvas tall. Uniform border so it can be stretched. |
| G5 | `UI__scroll_track.png` | tall | Полоса прокрутки (длинные списки, журнал) | A long thin vertical groove of dark iron with a brass cap at each end, plain inside. Down the whole canvas height, very thin, transparent to the left and right. |
| G6 | `UI__scroll_grip.png` | square | Ползунок полосы прокрутки | A small vertical brass slider block with three engraved grip lines, fills the middle third of the canvas. With G5 attached. |
| G7 | `UI__slider_track.png` | wide | Громкость в настройках | A long thin horizontal groove of dark iron with brass end caps and small evenly spaced notches, plain inside. Across the canvas width, very thin. |
| G8 | `UI__slider_knob.png` | square | Ручка ползунка громкости | A round brass knob with a ridged edge and a small dark dot on top, seen from the front, fills the middle third of the canvas. With G7 attached. |
| G9 | `UI__count_badge.png` | square | Счётчик на кнопке («3 новых слуха») — цифру ставит игра | The same wax as the attached `art/ui/WAX__seal.webp`, but a small round seal with NO emblem: a plain flat centre, fills the middle third of the canvas. With WAX__seal attached. |
| G10 | `UI__toast.png` | wide | Всплывающее сообщение («Получено: 3 шестерни»). Растягивается | A long narrow strip of aged parchment with a torn left edge, pinned by one brass tack at the right end, empty. Across the canvas width, about one sixth of the canvas tall. |
| G11 | `UI__new_marker.png` | square | Пометка «новое» на кнопке, модуле, карте | A tiny faceted amber gem in a brass claw setting, glowing faintly, fills the middle quarter of the canvas. |
| G12 | `UI__key_cap.png` | square | Подсказки обучения: клавиша («Пробел», «Esc» — надпись ставит игра) | An old typewriter key: a round brass rim with a plain dark ivory face, seen from the front, fills the middle half of the canvas. |
| G13 | `UI__mouse__left.png` | square | Обучение: «зажмите левую кнопку» | An old-fashioned computer mouse reimagined as a brass and dark-wood device with two buttons and a small wheel, seen from above, the LEFT button glowing warm amber. Fills the middle half of the canvas. |
| G14 | `UI__mouse__wheel.png` | square | Обучение: «колесо — приближение» | Exactly the same device as the attached G13, the left button not glowing, the wheel glowing warm amber. With G13 attached. |
| G15 | `UI__loading_gear.png` | square | Загрузка (игра вращает) | A single brass cogwheel with eight teeth and four spokes, perfectly round and centred, seen straight from the front, fills the middle half of the canvas. |
| G16 | `UI__price_tag.png` | wide | Цена в лавке (сумму ставит игра) | A small paper price tag with a hole and a loop of string at the left end, aged, empty. Centred, about one third of the canvas wide. |
| G17 | `UI__ribbon_bookmark.png` | tall | Закладки журнала и бестиария (цвет меняет игра) | A long vertical silk bookmark ribbon of faded parchment colour with a forked swallow-tail bottom end. Down the whole canvas height, narrow. |

## H. Эффекты боя (13) — чат «Combat VFX»

Холст **square**. Светящиеся (H2, H4, H6, H7, H9, H12) — UI STYLE BLOCK + **BLACK BLOCK**; остальные — UI STYLE BLOCK
+ TRANSPARENT BLOCK. Игра сама их показывает на долю секунды, увеличивает и гасит. Папка `assets/ui/`.
Чёрный фон у светящихся не вырезается: игра накладывает их «светом» (чёрное исчезает само) — это я настрою при импорте.

| # | Файл | Когда в бою | Промт |
|---|---|---|---|
| H1 | `VFX__slash.png` | Удар ближнего боя (Удар, Штык, Зазубренный клинок) | Three curved parallel slash streaks from top-right to bottom-left, sharp ink strokes, pale silver with a thin dark-red edge, fading at the ends. |
| H2 | `VFX__muzzle_flash.png` | Выстрел | A bright muzzle flash burst seen from the side, flame petals pointing right, hot white core, amber and orange edges, a few sparks. |
| H3 | `VFX__blood_splatter.png` | Попадание по твари | A splash of dark red blood flying outwards from the centre, droplets and a few long drips, painterly, not cartoonish. |
| H4 | `VFX__sparks.png` | Попадание по броне, защита | A burst of bright orange and white metal sparks flying from the centre in all directions, short streaks. |
| H5 | `VFX__block.png` | Набран блок | A round shield shape of translucent pale brass light with engraved rivets on its rim, like a ghostly buckler, slightly see-through. |
| H6 | `VFX__fire.png` | Струя пламени | A roaring jet of flame from the left edge to the right, curling at the end, orange and amber with a white-hot core. |
| H7 | `VFX__electric.png` | Шоковый гарпун | Crackling branching electric arcs in cold blue-white, from the centre outwards, thin and jagged. |
| H8 | `VFX__smoke.png` | Дымовая завеса | A thick billowing cloud of grey smoke, soft edges, darker at the bottom, fills most of the canvas. |
| H9 | `VFX__flash.png` | Вспышка (ослепление) | A huge magnesium flash: a blinding white star burst with long thin rays, faint violet afterglow at the edges. |
| H10 | `VFX__net.png` | Железная сеть (поимка) | A heavy iron-chain net spread out flat as if just thrown, round lead weights on its edge, seen from the front. |
| H11 | `VFX__fear.png` | Удар по рассудку (страх) | Dark ink tendrils curling inwards from all sides with a few faint pale eyes among them, deep violet-black, smoky. |
| H12 | `VFX__heal.png` | Лечение, тоник | Soft rising motes of warm amber and pale green light in a gentle column, a faint glow at the bottom. |
| H13 | `VFX__crack.png` | Сломанная часть тела | A star-shaped crack like shattered bone or stone, black fracture lines from the centre with a dark red glow inside the cracks. |

## I. Картинки на картах (19) — чат «Card art»

На экране окно картинки около 176×98 px; импорт уменьшает `CARD__art__*` до 768 px по длинной стороне.

Окно картинки — верхние 40 % рамки карты (`art/ui/COMBAT__card_frame__*`). UI STYLE BLOCK, **без прозрачности**,
холст **wide**. Приложи готовую рамку `COMBAT__card_frame__attack.webp`: «This art goes into the window in the upper
part of this card frame.» Папка `assets/ui/`, имя `CARD__art__<id>.png`.

Общая часть, добавь к каждому промту:

```text
A small engraved illustration for a playing card, like an old book engraving coloured with muted watercolour.
One clear action in the centre, readable when small; dark soft edges fading into the card. The hunter, when shown,
wears a long dark coat, a wide-brimmed hat and a high collar (as on the attached hunter portrait, if attached).
```

| # | Файл | Карта | Промт |
|---|---|---|---|
| I1 | `CARD__art__strike.png` | Удар | The hunter swinging the iron-shod stock of his rifle in a hard blow, motion lines. |
| I2 | `CARD__art__guard.png` | Защита | The hunter braced behind a raised forearm with a riveted iron bracer, claws scraping off it. |
| I3 | `CARD__art__shot.png` | Выстрел | A long hunting rifle firing to the right, smoke and a muzzle flash. |
| I4 | `CARD__art__reload.png` | Перезарядка | Gloved hands pushing brass cartridges into an open rifle breech. |
| I5 | `CARD__art__read_the_beast.png` | Изучить тварь | The hunter's eye behind a brass monocle lens; reflected in the lens, the silhouette of a creature with marked weak points. |
| I6 | `CARD__art__sidestep.png` | Уклонение | The hunter's coat swirling as he steps aside, a claw missing him by an inch. |
| I7 | `CARD__art__shock_harpoon.png` | Шоковый гарпун | A barbed harpoon on a chain, crackling with cold blue electricity. |
| I8 | `CARD__art__flash.png` | Вспышка | A brass magnesium flash lamp held up, exploding with white light. |
| I9 | `CARD__art__smoke_screen.png` | Дымовая завеса | Brass bellows on the hunter's belt puffing a thick grey cloud of smoke. |
| I10 | `CARD__art__serrated_edge.png` | Зазубренный клинок | A serrated bayonet blade tearing through, drops of dark blood on its teeth. |
| I11 | `CARD__art__harpoon_shot.png` | Выстрел гарпуном | A harpoon flying from the rifle's barrel trailing its chain. |
| I12 | `CARD__art__gout_of_flame.png` | Струя пламени | A brass nozzle under the rifle barrel spitting a jet of fire. |
| I13 | `CARD__art__overcharge.png` | Перегрузка | A brass capacitor coil on the rifle glowing red-hot, steam hissing from it. |
| I14 | `CARD__art__bayonet_thrust.png` | Удар штыком | A rifle with a long bayonet lunging forward in a straight thrust. |
| I15 | `CARD__art__iron_net.png` | Железная сеть | A weighted iron-chain net thrown wide in the air. |
| I16 | `CARD__art__tonic_of_morrell.png` | Тоник Моррелла | A small glass vial of glowing red tonic with a wax seal of House Morrell (a stylised rose). |
| I17 | `CARD__art__hounds_rage.png` | Ярость гончих | The hunter's shadow on a wall turning into a snarling hound's head. |
| I18 | `CARD__art__panic.png` | Паника | Trembling gloved hands dropping cards, ink blots with staring faces around them. |
| I19 | `CARD__art__dread.png` | Ужас | A tall dark shape looming in a doorway, only its pale eyes visible, the hunter tiny before it. |

## J. Иконки (2 листа) — чат «Icons»

Как в [icons.md](icons.md): **одна картинка на лист**, иконки по слотам раскладки, прозрачный фон. Приложи раскладку и
2 готовые иконки того же стиля. Сохрани в `assets/icons/`; я добавлю наборы в каталог `data/ui/icons.json` при импорте.

**J1 `MECHANISM__sheet.png`** — 4 иконки в ряд, раскладка `docs/assets/templates/icons/DIRECTION__grid.png`,
стиль OBJECT (приложи `art/ui/icons/ARMOR__helmet.webp`, `ARMOR__chestplate.webp`). Механизмы брони (GDD §5):

```text
One image: four game icons in one row, exactly in the numbered slots of the attached layout guide; do not draw the
slot numbers or the guide. ICON STYLE — OBJECT: a painted game icon of an object, slight 3/4 view, thick dark ink
outline, painted metal / leather / wood / glass with wear, warm light from the top-left — exactly the look of the
attached icons. Readable at 64 px. Transparent background. No text.
1 lantern_of_revealing: a small brass hunter's lantern with a lens shutter, cold pale light inside.
2 smoke_bellows: small leather-and-brass bellows with a nozzle, a puff of grey smoke.
3 riveted_plates: two overlapping riveted iron armour plates.
4 quick_holster: a leather holster with brass buckles and a cartridge loop.
```

**J2 `SETTINGS__sheet.png`** — 5 иконок в ряд, раскладка `docs/assets/templates/icons/OUTCOME__grid.png`,
стиль SYMBOL (приложи `art/ui/icons/UI__settings.webp`, `UI__save.webp`). Для экрана настроек:

```text
One image: five game icons in one row, exactly in the numbered slots of the attached layout guide; do not draw the
slot numbers or the guide. ICON STYLE — SYMBOL: a small game symbol icon that must read at 32 px: one simple bold
shape, cast in dark tarnished brass like a token or engraved badge, thick dark outline, minimal inner detail.
Exactly the look of the attached icons. Transparent background. No text.
1 sound: a brass horn speaker with three sound waves.
2 music: a brass music box with a small crank.
3 language: an open book with a quill across it.
4 fullscreen: four brass corner brackets pointing outwards.
5 hints: a brass hand lantern with a small curled flame and a keyhole on its base.
```

## K. Расследование (11) — чат «Investigation»

Плашка слуха (`RUMOR__diamond`), табличка контракта и доска в таверне уже есть. Нужны **листовка** (её вешают на
столб Костровой площади, GDD §20) и **картинки слухов** — иллюстрация слева на табличке слуха (GDD §8.1).
Папка `assets/ui/`.

| # | Файл | Холст | Блоки | Промт |
|---|---|---|---|---|
| K1 | `RUMOR__leaflet.png` | tall | UI + TRANSPARENT | A single cheap paper leaflet, slightly crumpled, torn bottom corner, a rusty nail through the top, rain stains; the paper is EMPTY (the game prints the text). |
| K2–K11 | `RUMOR__art__<id>.png` (общие картинки «место и след»; какая к какому признаку твари — решу при подключении) | square | SCENE, без прозрачности | Общая часть: `A small eerie illustration for a rumor, like a witness's memory: one place at night, no creature visible, only its traces. Soft dark vignette.` + строка ниже |

| Файл | Тема слуха (тег места/следа) | Промт |
|---|---|---|
| `RUMOR__art__water.png` | у воды | Shallow black water in a flooded alley, small wet handprints climbing the wall above it. |
| `RUMOR__art__rooftops.png` | крыши | Wet slate rooftops, a broken chimney, long scratch marks along the tiles, a dropped shoe. |
| `RUMOR__art__church.png` | церковь | Inside a dark chapel, candles blown out in a line, one pew overturned. |
| `RUMOR__art__underground.png` | под землёй | Stairs down into a flooded cellar, grey fog rising, a lantern left on the steps. |
| `RUMOR__art__street.png` | улица | An empty lane under a single gas lamp, three parallel furrows gouged into the cobbles. |
| `RUMOR__art__home.png` | дом | An empty child's bed by an open window, the curtain blowing, dust on the sill. |
| `RUMOR__art__graveyard.png` | кладбище | A paupers' graveyard, an opened grave, earth thrown out from below, a crow on a marker. |
| `RUMOR__art__fog.png` | туман | A street swallowed by fog, the silhouette of something far too tall barely visible. |
| `RUMOR__art__moon.png` | луна, ночь | A pale full moon over roofs, a window with a sleeper and grey dust on the sill. |
| `RUMOR__art__workshop.png` | механизмы, ржавчина | A rusted workshop, metal torn like paper, rust stains in the shape of footprints. |

## L. Экраны итогов (8) — чат «Results»

Папка `assets/ui/`. Текст ставит игра.

| # | Файл | Холст | Блоки | Где в игре | Промт |
|---|---|---|---|---|---|
| L1 | `SCREEN__victory.png` | wide | SCENE | Победа в бою (фон под наградами) | Grey dawn over wet slum roofs; the hunter, seen from behind, stands over the dark fallen shape of a creature, wiping his blade; steam rising. The right half calm and dark for panels. |
| L2 | `SCREEN__hunters_fall.png` | wide | SCENE | Падение охотника (0 здоровья) | The hunter collapsed face down on wet cobbles in the rain, his hat fallen beside him, his lantern rolling away still lit; dark figures of nuns approaching through the fog. |
| L3 | `SCREEN__day_end.png` | wide | SCENE | Конец дня (итоги) | A garret window at night, rain on the glass, a candle just snuffed out with a curl of smoke, the dark roofs outside. Calm, the centre dark for panels. |
| L4 | `SCREEN__rent_notice.png` | tall | UI + TRANSPARENT | Напоминание об аренде | A landlord's notice: a sheet of aged paper with an engraved empty border, a blood-red wax seal at the bottom, nailed at the top; the paper is EMPTY. |
| L5 | `SCREEN__loot_sack.png` | square | UI + TRANSPARENT | Добыча после боя | An open leather sack spilling brass gears, rusty scrap, a small circuit board and one long bloody fang. |
| L6 | `SCREEN__level_up.png` | square | UI + TRANSPARENT | Новый уровень | A brass hunter's medal on a dark red ribbon, a gear-and-hook emblem in the centre, rays of warm light behind it. |
| L7 | `SCREEN__voice_stage.png` | wide | SCENE | Новая стадия Голоса (порча) | The hunter looking into a cracked dark mirror; his reflection smiles with faint red eyes and too many teeth. |
| L8 | `SCREEN__register_leaflet.png` | tall | UI + TRANSPARENT | Реестр Люмена — ранг в конце главы | A printed broadsheet of the Lumen Register: an engraved empty header frame, empty columns, a round official stamp; all text areas EMPTY. |

## M. Портрет охотника по стадиям Голоса (3) — чат «Hunter portrait»

UI STYLE BLOCK + TRANSPARENT BLOCK, square, `assets/ui/`. Приложи `art/ui/COMBAT__hunter_portrait.webp`:
«The same man, the same medallion, rim, framing and pose. Change only what is written.»

| # | Файл | Стадия | Промт |
|---|---|---|---|
| M1 | `COMBAT__hunter_portrait__voice1.png` | 1 | Dark veins creeping up his neck, one eye slightly bloodshot. |
| M2 | `COMBAT__hunter_portrait__voice2.png` | 2 | Grey-tinged skin, both eyes with a faint red glow, a scar that has turned black. |
| M3 | `COMBAT__hunter_portrait__voice3.png` | 3 | Half of the face cracked like dry clay with red light inside the cracks, the eyes fully red, a thin trickle of black blood. |

## N. Бестиарий, поимка, вскрытие (5) — чат «Bestiary»

Силуэты тварей уже есть (`art/monsters/*__silhouette__*`) — игра ставит их на страницы. Папка `assets/ui/`.

| # | Файл | Холст | Блоки | Где в игре | Промт |
|---|---|---|---|---|---|
| N1 | `BESTIARY__book.png` | wide | UI, без прозрачности | Раскрытая книга бестиария (фон экрана) | An old open leather-bound book seen from above on a dark table, two blank aged pages, a brass clasp, a pressed feather; the pages EMPTY. |
| N2 | `BESTIARY__specimen_jar.png` | tall | UI + TRANSPARENT | Образец крови в бестиарии | A tall glass specimen jar with a brass lid, half filled with dark red liquid, an empty paper label. |
| N3 | `CAPTURE__cage.png` | square | UI + TRANSPARENT | Тварь поймана | A heavy iron cage with a riveted floor and a chained door, empty inside (the game puts the creature's silhouette there). |
| N4 | `RESEARCH__table.png` | wide | SCENE | Вскрытие в Склепе-скриптории | A dissection table in a vaulted crypt under a hanging lamp, surgical tools laid out on cloth, specimen jars on shelves; the table empty. |
| N5 | `RESEARCH__magnifier.png` | square | UI + TRANSPARENT | Указатель «изучить часть тела» | A brass magnifying glass with a dark wooden handle, the lens clear. |

## O. Сюжет (5) — чат «Story» (O5 — фаза 9)

| # | Файл | Холст | Блоки | Где в игре | Промт |
|---|---|---|---|---|---|
| O1 | `UI__dialogue_box.png` | wide | UI + TRANSPARENT | Окно диалога внизу экрана. Растягивается | A long low panel of dark wood and parchment with a brass frame, rivets in the corners, empty. Across the canvas width, about one third of the canvas tall. Uniform border so it can be stretched. |
| O2 | `UI__name_plate.png` | wide | UI + TRANSPARENT | Имя говорящего над окном диалога | A small brass name plate with notched ends, empty. Centred, about one third of the canvas wide. With O1 attached. |
| O3 | `STORY__prologue.png` | wide | SCENE | Заставка пролога | The hunter arriving at the Grey Chapels at night by the last tram, stepping off at the depot, the Ringwall towering behind the roofs. |
| O4 | `STORY__chapter_1.png` | wide | SCENE | Заставка главы I | The Old Grey Chapel with its broken roof at night, grey candles, a crowd of hooded figures in the yard, the hunter watching from a roof. |
| O5 | `STORY__chapter_2.png` | wide | SCENE | Заставка главы II | The Broken Hoist over the abyss, its cage being lowered into the fog, the hunter standing inside with a lantern. |

## P. События города (9) — чат «Events»

SCENE STYLE BLOCK, wide, без прозрачности, `assets/ui/`, имя `EVENT__art__<id>.png`. Окно события: картинка + текст.

| Файл | Событие (GDD §15) | Промт |
|---|---|---|
| `EVENT__art__storm_season.png` | Сезон бурь | Flooded streets in a storm, water pouring down stairs, lamps swinging, a strange carved box washed up on the steps. |
| `EVENT__art__dusk_night.png` | Ночь Сумерек | A night festival in narrow streets, paper lanterns, masked dancers, hooded figures with grey candles among them. |
| `EVENT__art__lumen_register.png` | Реестр Люмена | A crowd reading freshly pasted broadsheets on a wall under a gas lamp. |
| `EVENT__art__fog_breach.png` | Прорыв тумана | Grey fog pouring over the top of the Ringwall like a waterfall, shapes moving inside it, people running. |
| `EVENT__art__hound_war.png` | Война гончих | Two gangs facing each other across a street, hound banners against woven banners, torches. |
| `EVENT__art__uprising_below.png` | Восстание снизу | Barricades of carts and planks at the lifts, workers with lanterns and tools, smoke. |
| `EVENT__art__shaft_7.png` | Падение шахты 7 | A huge collapsed mine shaft head, twisted iron, dust rising into the night. |
| `EVENT__art__grey_plague.png` | Серая чума | A quarantined street, doors marked with grey chalk crosses, a plague doctor in a beaked mask. |
| `EVENT__art__masked_moon.png` | Маска луны | An eclipse over the city, a dark moon with a pale ring, faces at every window looking up. |

## Q. Значок и Steam — фаза 10

| # | Файл | Холст | Промт |
|---|---|---|---|
| Q1 | — | — | **Не генерировать:** значок игры вырежу из готовой печати `art/ui/WAX__seal.webp` (крюк с фонарём на красном воске). Если на 32 px не читается — приложи печать и попроси: `The same seal simplified to read at 32 px: bolder shapes, fewer details.` |
| Q2 | `assets/ui/APP__capsule.png` | wide | SCENE: key art — the hunter on a rooftop with his rifle, a huge shadowy creature rising from the fog behind the Ringwall, the slum lights below. Leave the top third calmer for the title (added later). |

## R. Новые твари — только после твоего решения

В GDD §20 у Серых Часовен есть беды, для которых **ещё нет тварей**: вурдалаки (Нижние дворы), крысиные стаи
(Пепельный квартал), «то, что лезет снизу» (Дорожка над Бездной). Если решишь их добавить — я заведу их в данные,
и [creatures.md](creatures.md) сам выдаст полные промты (4 картинки на тварь). Наброски, чтобы посмотреть вид
(SCENE STYLE, square, `assets/refs/` — в игру не идут):

| Набросок | Промт |
|---|---|
| Вурдалак | A gaunt grave-eating ghoul crouching on an opened grave, grey skin, long dirty nails, a torn burial shroud. |
| Крысиная стая | A swarm of soot-black rats moving as one shape, many red eyes, a crown of gnawed bones in the middle. |
| Тварь из Бездны | A long-limbed pale thing climbing over a stone parapet out of grey fog, too many joints, no face. |

## Проверка после генерации

- Имена файлов — точно как в таблицах; папки — как указано.
- Прозрачные элементы — без белого квадрата и «шахматки» (проверить на тёмном и светлом).
- Эффекты с BLACK BLOCK — вокруг чисто чёрный, ничего лишнего.
- Бумаги (K1, L4, L8, N1) — **без текста**: текст ставит игра.
- Наборы одного вида: G5–G6, G7–G8, G13–G14, I1–I19, M1–M3, O1–O2.
- Пришли результат и напиши «импортируй арт».

## Вопросы владельцу

- Шрифты: какой нравится для заголовков — *Ruslan Display* (славянская вязь) или *Old Standard TT* (старая книга)?
- Новые твари для Серых Часовен (часть R) — добавлять?
- Картинки на картах (часть I) — делать сейчас или позже?
