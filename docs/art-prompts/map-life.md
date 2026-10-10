# Art Prompts — life on the district map (people, scenes, animals, vehicles, decor)

Сейчас люди на карте Серых Часовен — нарисованные точки, они не двигаются. Этот файл — всё, чтобы карта **ожила**:
жители занимаются делами (торгуют, играют музыку, патрулируют, воруют, лечат, хоронят), ходят по улицам, рядом с
местами стоят сценки, над крышами дым, на улицах горят костры и фонари. Плюс немного декора самой карты и интерфейса.

Hand-written; prompts in English, instructions in Russian. Карта — [grey-chapels-map/](grey-chapels-map/README.md),
район — GDD §20, фракции — GDD §12.

## Как это работает в игре

- Люди, животные и транспорт — **отдельные маленькие картинки поверх карты**. Игра их ставит, водит по улицам
  (тот же граф улиц, что у героя), покачивает при ходьбе, разворачивает (зеркалит) и прячет по времени суток.
- **Анимацию делает игра**, не картинки: ходьба = покачивание и сдвиг; где нужно движение рук (бард, прачка, флаг) —
  две позы A и B в соседних слотах, игра их чередует.
- **Ходячим нужны две стороны**: «идёт к нам, влево-вниз» и «идёт от нас, вправо-вверх». Вправо-вниз и влево-вверх
  игра получает зеркалом.
- **Масштаб:** на карте дом ≈ 80 px, человек ≈ 30–36 px. Рисуем крупно, импорт уменьшает. Силуэт должен читаться
  даже маленьким.
- **Камера** как у карты: высоко сверху под углом (≈ 60° вниз), видны шляпы, плечи и немного фигуры. **Тень под
  ногами игра рисует сама** — в картинке тени нет.

## Порядок

| Часть | Что | Картинок | Когда |
|---|---|---|---|
| **A** | Жители: 7 листов по 8 фигур (торговля, улица, закон, тени, учёные и врачи, работяги и охотники, животные) | 7 листов (56 фигур) | с экраном района |
| **B** | Транспорт: трамвай, телега с лошадью, тачка, катафалк, полицейский фургон, ручная тележка | 6 | с экраном района |
| **C** | Сценки у мест: концерт барда, торг, круг культистов, очередь в лазарет, драка у таверны, место преступления, похороны, картёжники, гадалка, расчёт пушки на стене | 10 | с экраном района |
| **D** | Живой декор карты: костры, огни, искры, дым, бельё, флаги, мелочи на улицах | 16 | с экраном района |
| **E** | Состояния района (бунт, карантин, праздник, затопление) — накладки | 4 | фаза 7 |
| **F** | Картография и декор интерфейса: картуш с названием, таблички улиц, булавка, рамка карты, орнамент, пыль, клякса | 9 | когда удобно |

## Блоки стиля

Те же правила, что в [next-art-pack.md](next-art-pack.md). Для этого файла — два своих блока:

```text
LIFE STYLE BLOCK:
Realistic painterly figures for a dark Victorian slum at night after rain, the same look as the attached map piece:
desaturated cold palette (wet slate grey, soot black, blue-grey, dark brick brown), small warm amber highlights from
lamps. Each figure has a crisp, readable silhouette and a thin cool rim light so it reads on dark wet cobbles when tiny.
Camera: high above, looking down at about 60 degrees, like the attached map — we see hats, shoulders and the top of
the figure, a little of the body. Clothing of the 1880s with gaslight-and-steel details (brass, rivets, leather).
No text, no letters, no numbers, no logos.
```

```text
SPRITE BLOCK:
Transparent background (real alpha channel). No ground, no floor, no cast shadow, no frame.
Each element is complete and not cut off, with a clear empty margin around it.
```

Для листов (часть A) добавь к ним:

```text
SHEET: one image with eight separate figures on a 4 x 2 grid, exactly in the numbered slots of the attached layout
guide (slot 1 top-left, reading order). Every figure stands in the middle of its slot, all at the same scale (an
adult fills about two thirds of the slot height). Figures never touch or overlap. Do not draw the slot numbers,
lines or the guide.
```

**Что приложить в каждом чате:** кусок игровой карты для масштаба и цвета (у тебя в `assets/district_maps/`):
`GREY__detail__r0c1.png` — Пепельный рынок (для торговли и улицы), `GREY__detail__r1c1.png` — центр: часовня,
Костровая площадь, крыши (для остальных листов и сценок), `GREY__detail__r2c0.png` — трамвайное депо (для
транспорта). Для листов ещё раскладку `docs/assets/templates/icons/ACTION__grid.png` (8 слотов 4 × 2).
BLACK BLOCK (части D и F8) — в [art-backlog.md](art-backlog.md), остальные блоки — в [next-art-pack.md](next-art-pack.md).

**Сохранять:** `assets/ui/` с точными именами. Листы `LIFE__*__sheet.png` я разрежу на отдельные фигуры при импорте;
пары кадров (бард 1–2, бельё D8–D9, флаг D10–D11) импорт будет обрезать по общей рамке, чтобы они не «прыгали».
Группы в одном слоте (две торговки, стражники парой, крысы, вороны) — одна картинка: ходит или стоит целиком.

## A. Жители — 7 листов (чат «Map life — people»)

LIFE STYLE + SPRITE + SHEET, холст **wide**. «→ к нам» = walking towards the viewer and to the left;
«→ от нас» = the same person walking away from the viewer and to the right (seen from behind).

### A1 `LIFE__trade__sheet.png` — торговля (Пепельный рынок, Крюков переулок)

```text
1 a chestnut seller standing behind a small iron brazier cart, glowing coals, paper cones.
2 a candle seller with a wide tray of grey candles hanging from her neck.
3 a rag-picker with a huge sack over the shoulder, walking towards the viewer and to the left.
4 the same rag-picker walking away from the viewer and to the right, seen from behind.
5 a porter bent under a stack of crates on his back, walking towards the viewer and to the left.
6 the same porter walking away from the viewer and to the right, seen from behind.
7 two women haggling over a basket of turnips, one pointing, as ONE figure group.
8 a butcher in a stained apron standing at a small stall with meat on iron hooks.
```

### A2 `LIFE__street__sheet.png` — улица и музыка (Костровая площадь, таверна)

```text
1 a wandering bard playing a hurdy-gurdy, standing, cranking arm DOWN (pose A).
2 exactly the same bard, cranking arm UP (pose B); nothing else changes.
3 a thin fiddler playing, eyes closed, hat on the ground in front of him (no coins drawn as text).
4 a street preacher standing on a crate, one arm raised to the sky.
5 a beggar sitting against a wall with a tin cup, blanket over the knees.
6 a drunkard leaning on a gas-lamp post with a bottle.
7 two ragged children running towards the viewer and to the left, one with a hoop and a stick.
8 a washerwoman carrying a basket of wet laundry on her hip.
```

### A3 `LIFE__law__sheet.png` — закон и порядок (Железное Бдение, городская стража, сыщики)

```text
1 two Iron Vigil watchmen in dark iron half-armour and helmets with halberds, patrolling side by side towards the
  viewer and to the left (one figure group).
2 the same pair walking away from the viewer and to the right, seen from behind.
3 a night constable with a bull's-eye lantern and a whistle, walking towards the viewer and to the left.
4 the same constable walking away from the viewer and to the right, seen from behind.
5 a detective in an Inverness cape and deerstalker crouching, examining the ground with a brass magnifier.
6 the same detective walking towards the viewer and to the left, hands behind his back.
7 a Ringwall guard in a long grey coat and steel helmet with a long musket on his shoulder, standing.
8 a bill-poster with a bucket and brush pasting a blank paper notice on a wall.
```

### A4 `LIFE__shadow__sheet.png` — тени (воришки, контрабанда, культ, похитители тел)

```text
1 a hunched pickpocket sneaking towards the viewer and to the left, one hand reaching out.
2 the same pickpocket sneaking away from the viewer and to the right, seen from behind.
3 a young thief running towards the viewer and to the left clutching a stolen purse, coat flying.
4 a lookout leaning in a dark doorway, hat low, smoking.
5 a Scarlet Supper smuggler with a red scarf carrying a small crate, walking towards the viewer and to the left.
6 a hooded Grey Communion cultist in grey robes holding a grey candle, walking towards the viewer and to the left.
7 the same cultist walking away from the viewer and to the right, seen from behind.
8 a body-snatcher pushing a handcart with a shrouded body, walking towards the viewer and to the left.
```

### A5 `LIFE__learned__sheet.png` — учёные и врачи (Коллегия Люмен, Дом Моррелл, Пепельные сёстры)

```text
1 a Lumen Collegium scholar in a gown with a stack of books and a small brass instrument, walking towards the viewer
  and to the left.
2 the same scholar walking away from the viewer and to the right, seen from behind.
3 a House Morrell plague doctor in a long black coat and beaked mask with a cane, walking towards the viewer and to the left.
4 the same plague doctor walking away from the viewer and to the right, seen from behind.
5 an Ash Sister nun in a grey habit with a basket of bandages, walking towards the viewer and to the left.
6 the same nun walking away from the viewer and to the right, seen from behind.
7 a Register surveyor standing at a brass tripod instrument, taking a measurement.
8 an alchemist standing and holding up a glowing green flask, examining it.
```

### A6 `LIFE__workers__sheet.png` — работяги и охотники

```text
1 a lamplighter with a long brass pole walking towards the viewer and to the left.
2 the same lamplighter standing, pole raised high, lighting a lamp (a tiny flame at the pole tip).
3 a chimney sweep standing with brushes and a rope coil, soot-black face.
4 a gravedigger digging with a spade, a pile of earth beside him.
5 a coal heaver carrying a sack of coal on his back, walking towards the viewer and to the left.
6 a Pale Hounds hunter with a fur collar and a big grey hound on a chain, walking towards the viewer and to the left.
7 a Weavers hunter in a long coat with a weighted net over the shoulder, walking towards the viewer and to the left.
8 a Rusty Cog mechanic in goggles carrying a big brass gear, walking towards the viewer and to the left.
```

### A7 `LIFE__animals__sheet.png` — животные

```text
1 a skinny stray dog trotting towards the viewer and to the left.
2 a black cat sitting, seen from above as if on a roof ridge.
3 three crows standing together.
4 one crow flying, wings spread, seen from above.
5 a pack of four rats running towards the viewer and to the left.
6 a small group of grey pigeons pecking.
7 two thin chickens.
8 a big grey hound lying down, head on its paws.
```

## B. Транспорт — 6 картинок (чат «Map life — vehicles»)

LIFE STYLE + SPRITE, **вид прямо сверху** (как крыши на карте), **едет вправо** — игра поворачивает по улице.
Холст **wide**, `assets/ui/`.

| # | Файл | Промт |
|---|---|---|
| B1 | `LIFE__tram.png` | An old two-axle tram car seen from straight above, facing right: a long roof with vents and a trolley pole, the same colours as the old tram car in the depot on the attached map piece (r2c0). |
| B2 | `LIFE__cart_horse.png` | A horse pulling a covered wooden cart, seen from straight above, facing right, a driver with a hat on the bench. |
| B3 | `LIFE__handcart.png` | A two-wheeled wooden handcart loaded with scrap and sacks, a man pushing it, seen from straight above, facing right. |
| B4 | `LIFE__hearse.png` | A black funeral hearse drawn by a black horse with a plume, glass sides, seen from straight above, facing right. |
| B5 | `LIFE__police_wagon.png` | A closed black Iron Vigil prison wagon with barred windows and a lantern, two horses, seen from straight above, facing right. |
| B6 | `LIFE__wheelbarrow.png` | A wooden wheelbarrow full of coal, seen from straight above, facing right. |

## C. Сценки у мест — 10 картинок (чат «Map life — scenes»)

LIFE STYLE + SPRITE, холст **square**, `assets/ui/`. Группа людей, стоящая на месте (игра ставит у нужного места и
слегка «оживляет» покачиванием). Общая часть: `A small group scene that will stand on the map, seen from high above at
about 60 degrees, the group about the size of two houses.`

| # | Файл | Где | Промт |
|---|---|---|---|
| C1 | `LIFE__scene__bard_concert.png` | Костровая площадь | A bard with a hurdy-gurdy on a barrel by a bonfire, a ring of listeners, one dancing, a child sitting on the cobbles. |
| C2 | `LIFE__scene__market_crowd.png` | Пепельный рынок | A crowd around a patched canvas stall, people haggling, a boy stealing an apple behind the seller's back. |
| C3 | `LIFE__scene__cult_circle.png` | Часовенный двор | Hooded grey-robed cultists kneeling in a circle around a chalk sign (only lines and circles, no letters) with grey candles. |
| C4 | `LIFE__scene__infirmary_queue.png` | Лазарет | A queue of ragged patients with bandages, an Ash Sister nun at the front with a lantern. |
| C5 | `LIFE__scene__tavern_brawl.png` | Таверна | Two men fighting in the mud by a tavern door, a ring of cheering drinkers with mugs. |
| C6 | `LIFE__scene__crime_scene.png` | у слуха (фаза 3) | A body under a sheet on wet cobbles, a detective crouching with a magnifier, two Iron Vigil watchmen holding lanterns, a few onlookers. |
| C7 | `LIFE__scene__funeral.png` | Безымянное кладбище | A small funeral procession carrying a plain coffin, mourners in black with umbrellas, a priest with a book. |
| C8 | `LIFE__scene__card_players.png` | у таверны, во дворах | Four men playing cards on an upturned barrel under a lantern, coins and a bottle on it. |
| C9 | `LIFE__scene__fortune_teller.png` | рынок | An old fortune teller under a small patched tent with a crystal ball and candles, a young woman sitting before her. |
| C10 | `LIFE__scene__wall_cannon_crew.png` | Кольцевая стена | Three Ringwall guards loading a cannon pointing out over the fog, cannonballs stacked, an officer with a spyglass. |

## D. Живой декор карты — 16 картинок (чат «Map life — decor»)

Светящееся — UI STYLE + **BLACK BLOCK** (из [art-backlog.md](art-backlog.md)), игра накладывает его светом и мерцает.
Остальное — LIFE STYLE + SPRITE. Вид — как у карты, сверху. Холст **square**, `assets/ui/`.

| # | Файл | Блок | Что делает игра | Промт |
|---|---|---|---|---|
| D1 | `LIFE__fx__bonfire.png` | BLACK | Мерцает на кострах | A bonfire seen from above: a ring of orange flames with a white-hot centre and a few sparks. |
| D2 | `LIFE__fx__lamp_glow.png` | BLACK | Ореол у фонарей | A soft round warm amber glow of a gas lamp with a bright tiny core, fading smoothly to black. |
| D3 | `LIFE__fx__window_glow.png` | BLACK | Окна загораются вечером | A small rectangular warm window light with a soft halo, fading to black. |
| D4 | `LIFE__fx__sparks.png` | BLACK | Искры из трубы «Ржавой Шестерни» | A small burst of rising orange forge sparks. |
| D5 | `LIFE__fx__candles.png` | BLACK | Свечи Моста Свечей, у Бога в стене | A row of many tiny candle flames with soft glows. |
| D6 | `LIFE__fx__searchlight.png` | BLACK | Луч прожектора с башни стены ходит по туману | A long cone of pale searchlight beam from a small bright source at the left, fading to the right, with fog in it. |
| D7 | `LIFE__deco__smoke.png` | SPRITE | Дым из труб, игра пускает его вверх и растворяет | A soft puff of grey chimney smoke seen from above, wispy edges. |
| D8 | `LIFE__deco__laundry_a.png` | SPRITE | Бельё на верёвке, кадр A | A washing line between two short posts with grey shirts and sheets hanging, seen from above, the cloth blowing left. |
| D9 | `LIFE__deco__laundry_b.png` | SPRITE | Кадр B | Exactly the same washing line, the cloth blowing right. Nothing else changes. With D8 attached. |
| D10 | `LIFE__deco__banner_a.png` | SPRITE | Флаг на башне стены, кадр A | A tattered grey-and-dark-red pennant on a pole, waving left, no emblem with letters. |
| D11 | `LIFE__deco__banner_b.png` | SPRITE | Кадр B | Exactly the same pennant waving right. With D10 attached. |
| D12 | `LIFE__deco__leaflets.png` | SPRITE | Новые листовки на столбе Костровой площади | A cluster of pinned paper leaflets seen from above, blank, a few torn. |
| D13 | `LIFE__deco__chalk_sign.png` | SPRITE | Знак культа появляется после событий | A chalk sign drawn on cobbles: circles, a spiral and an eye shape in white chalk lines only, no letters. |
| D14 | `LIFE__deco__blood.png` | SPRITE | След нападения твари (у слуха) | A dark blood stain on wet cobbles with three parallel claw furrows. |
| D15 | `LIFE__deco__puddle_ring.png` | SPRITE | Круги на лужах в дождь | A thin pale ring of a raindrop ripple on water, very subtle. |
| D16 | `LIFE__deco__litter.png` | SPRITE | Мусор, листья — разбросать по улицам | Scattered wet paper scraps, dead leaves and a broken bottle, seen from above. |

## E. Состояния района — 4 накладки (фаза 7)

LIFE STYLE + SPRITE, square, `assets/ui/`. Игра ставит их на улицы, пока у района это состояние (GDD §14).

| # | Файл | Состояние | Промт |
|---|---|---|---|
| E1 | `LIFE__state__barricade.png` | бунт | A street barricade of overturned carts, barrels and planks, a burning torch on top, seen from above. |
| E2 | `LIFE__state__quarantine.png` | карантин | A rope barrier with hanging yellow warning cloths and a chalk-crossed door plank, seen from above. |
| E3 | `LIFE__state__garland.png` | праздник | A string of small paper lanterns hanging across a street between two poles, glowing warm, seen from above. |
| E4 | `LIFE__state__sandbags.png` | затопление | A low wall of sandbags across a street with water on one side, seen from above. |

## F. Картография и декор интерфейса — 9 картинок (чат «Map decor»)

UI STYLE BLOCK + TRANSPARENT BLOCK (из [next-art-pack.md](next-art-pack.md)), `assets/ui/`. Текст ставит игра.

| # | Файл | Холст | Где в игре | Промт |
|---|---|---|---|---|
| F1 | `MAP__cartouche.png` | wide | Название района в углу карты («Серые Часовни») | An ornate engraved cartouche of tarnished brass and parchment with curling scrolls, a small lantern at the top, the centre EMPTY. |
| F2 | `MAP__street_sign.png` | wide | Таблички улиц на карте (появляются при приближении) | A small old enamel street sign plate, dark blue-grey with a thin cream border and two rivets, chipped corners, EMPTY. Centred, about one third of the canvas wide. |
| F3 | `MAP__pin.png` | square | Отметка цели контракта на карте | A brass map pushpin with a round dark-red glass head, seen from slightly above. |
| F4 | `MAP__frame_corner.png` | square | Рамка по краям экрана карты (игра поворачивает на 4 угла) | An ornate L-shaped corner of a map frame: dark iron with brass filigree, a tiny compass star, the corner of the L in the top-left. |
| F5 | `UI__filigree.png` | wide | Орнамент над заголовками окон | A symmetrical engraved brass filigree ornament with curls and a small hook-and-lantern in the middle, thin, across the canvas width. |
| F6 | `UI__chain.png` | tall | Цепи, на которых «висят» таблички и окна | A vertical length of dark iron chain, down the whole canvas height. |
| F7 | `UI__wax_drip.png` | wide | Капли воска по верхнему краю окон | A strip of melted dark-red wax dripping down from a straight top edge, across the canvas width. |
| F8 | `UI__dust.png` | square | Пылинки в свете ламп (игра медленно двигает) | BLACK BLOCK instead of TRANSPARENT: tiny floating dust motes and specks of soft warm light scattered evenly. |
| F9 | `UI__ink_blot.png` | square | Переход между экранами (клякса растекается) | A big black ink blot with splashes and drips, solid black, the edges sharp. |

## Где кого ставить (предложение для экрана района)

| Зона | Днём | Ночью |
|---|---|---|
| Пепельный квартал | торговцы, носильщики, тряпичники, дети, бард, прачки, собаки | фонарщик, пьяницы, карманники, патруль, кошки |
| Хибары на крышах | трубочисты, голуби, дети на верёвочных мостах | контрабандисты, воришки, кошки |
| Часовенный двор | паломники, писарь, вороны | культисты, круг культа (сценка), свечи |
| Туманный лог | почти пусто, крысы | культист, похититель тел, крысы |
| Нижние дворы | могильщики, сёстры и очередь в лазарет, угольщики у депо, трамвай | похороны (по событию), катафалк, крысы |
| Дорожка над Бездной | стража стены, расчёт пушки, флаги | прожектор, редкий скорбящий у Бога в стене |

Чужие для трущоб люди (учёные Люмена, врачи Моррелла, Бдение, охотники Нордхала) — **редкие гости**, их появление
можно привязать к контрактам и событиям.

## Вопросы владельцу

1. **Стиль героя.** Герой сейчас — каменная фигурка на подставке, а жители будут живыми нарисованными людьми.
   Оставить так (герой выделяется как «фишка игрока») или сделать героя тоже живым человеком в том же стиле?
2. **Жители — только декор или с ними можно что-то делать?**
   - а) только декор;
   - б) по клику короткая фраза-сплетня (иногда с подсказкой к слуху);
   - в) редкие события: карманник крадёт пару монет, если пройти рядом; место преступления = новый слух.
3. **Время суток.** Менять жителей днём и ночью по таблице выше — да?
4. **Сколько людей на карте одновременно:** немного (≈ 20, тихо и мрачно) или много (≈ 50–60, шумные трущобы)?
