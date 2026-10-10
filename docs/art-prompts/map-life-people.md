# Art Prompts — people of the Grey Chapels (passers-by, local characters, groups, little stories)

Жители карты Серых Часовен — подробно. Цель: **за картой интересно наблюдать**. Обычные прохожие создают толпу,
местные персонажи живут по своему распорядку, люди собираются в группы ради дела, а маленькие сюжеты разыгрываются
сами: вор крадёт кошелёк — констебль свистит — погоня.

Остальная жизнь карты (транспорт, сценки у мест, огни, дым, декор) — [map-life.md](map-life.md). Блоки стиля
LIFE STYLE, SPRITE и SHEET — там же («Блоки стиля»). Hand-written; prompts in English, instructions in Russian.

## Три слоя жизни

| Слой | Доля людей на карте | Что делают | Части файла |
|---|---|---|---|
| **Обычные прохожие** | ~50 % | Идут по своим делам, останавливаются поболтать, прячутся от дождя, расступаются | A |
| **Местные персонажи** | ~20 % | Свои лица и привычки, свой распорядок дня, узнаваемы с первого взгляда | B |
| **Роли без имени** | ~15 % | Торговцы, стража, культисты, охотники — их может быть несколько сразу; плюс животные | F |
| **Группы и сюжеты** | ~15 % | Собираются ради дела: похороны, охота, облава, концерт; разыгрывают мини-истории | C, D |

## Как жители «играют» (что делает игра)

Картинки неподвижные — **движение и поведение делает игра**. Набор поведений:

| Поведение | Как выглядит |
|---|---|
| **Идёт** | По улицам от точки к точке, покачивается; скорость у каждого своя (старик медленно, мальчишка бегом) |
| **Стоит, глазеет** | Останавливается у лавки, костра, листовок; поворачивается то влево, то вправо |
| **Болтает** | Двое встречных останавливаются лицом друг к другу на 3–8 с, над головами значок (часть E) |
| **Работает** | Стоит на своём месте и чередует позы A и B (бард играет, прачка вешает бельё, могильщик копает) |
| **Собирается** | Идёт к событию: к барду, к драке, к листовкам; вокруг вырастает кружок зрителей |
| **Убегает** | От погони, от культа, от твари: бегом в переулок, двери закрываются |
| **Прячется от дождя** | В дождь часть прохожих раскрывает зонты (отдельные картинки), часть бежит под навесы |
| **Реагирует на героя** | Расступаются; дети бегут следом; карманник «присматривается»; культист отворачивается |

Чтобы толпа не повторялась, игра каждому прохожему слегка меняет **оттенок одежды, размер (±5 %), скорость и
паузы** и зеркалит его. 32 прохожих из части A на экране выглядят как сотня разных людей.

**Позы.** У каждого: идёт к нам (влево-вниз) и идёт от нас (вправо-вверх); игра получает остальные направления
зеркалом. У персонажей B добавлены позы действия A/B и особая поза.

## Как генерировать

- Все листы — **холст wide, 8 слотов 4 × 2**, раскладка `docs/assets/templates/icons/ACTION__grid.png`.
  Блоки: LIFE STYLE + SPRITE + SHEET (из [map-life.md](map-life.md)).
- Для масштаба и цвета приложи кусок карты из `assets/district_maps/` (у тебя): `GREY__detail__r0c1.png` (рынок),
  `GREY__detail__r1c1.png` (центр, часовня, крыши), `GREY__detail__r4c1.png` (нижние дворы, кладбище).
- **Один чат на часть** (A, B, C, F). В части B у каждого персонажа 4 позы — все четыре должны быть **одним и тем же
  человеком** (лицо, одежда, цвета); если персонаж вышел непохожим, приложи его прошлые позы и попроси переделать.
- Сохранять в `assets/ui/` с точными именами; листы я разрежу на отдельные фигуры при импорте.
- Позы одного персонажа импорт будет выравнивать по общей рамке, чтобы при смене поз фигура не «прыгала».

Общее для всех ходячих:

```text
"walking towards" = walking towards the viewer and to the left, seen from the front.
"walking away"    = the same person walking away from the viewer and to the right, seen from behind.
```

## A. Обычные прохожие — 8 листов, 32 человека (чат «People — passers-by»)

В каждом листе 4 человека × 2 позы. Все разные по возрасту, полу, сложению, походке и ноше.
В промт вставляй SHEET, блок «Общее для всех ходячих» и эту фразу, потом описание листа:

```text
Slots 1–2: person 1 (walking towards, walking away). Slots 3–4: person 2. Slots 5–6: person 3. Slots 7–8: person 4.
```

### A1 `LIFE__pass_workers__sheet.png` — рабочий люд

```text
Person 1 (slots 1–2): a broad dock-labourer type in a flat cap and rolled sleeves, a coil of rope on his shoulder.
Person 2 (slots 3–4): a skinny young apprentice in an oversized coat carrying a toolbox, walking fast.
Person 3 (slots 5–6): a middle-aged woman factory worker in a shawl and apron, a tin lunch pail in her hand.
Person 4 (slots 7–8): a tired old carpenter with a saw and planks under his arm, slightly limping.
```

### A2 `LIFE__pass_burdens__sheet.png` — с ношей

```text
Person 1: a young mother with a baby wrapped in a shawl, holding a small boy by the hand (one figure group).
Person 2: a stout woman with a big basket of cabbages on her head.
Person 3: a water-carrier with a wooden yoke and two buckets.
Person 4: a girl carrying a bundle of firewood on her back, bent forward.
```

### A3 `LIFE__pass_elders__sheet.png` — старики и калеки

```text
Person 1: a hunched old woman with a cane and a black headscarf, very slow.
Person 2: a one-legged war veteran on a crutch in a faded military coat with a medal.
Person 3: a bald old man in a moth-eaten top hat, muttering, carrying a birdcage with a canary.
Person 4: a blind old woman with a white stick, her hand on the shoulder of a small girl leading her (one group).
```

### A4 `LIFE__pass_pairs__sheet.png` — пары (каждая пара — одна фигура)

```text
Pair 1: a young couple walking arm in arm, sharing one coat over their shoulders.
Pair 2: two workers walking side by side, one gesturing as he talks.
Pair 3: an old married couple, the husband carrying a lantern, the wife holding his elbow.
Pair 4: two gossiping women with shopping baskets, heads close together.
```

### A5 `LIFE__pass_rain__sheet.png` — в дождь (игра включает их в дождь)

```text
Person 1: a man in a bowler hat under a black umbrella, walking fast.
Person 2: a woman holding her coat over her head, running.
Person 3: a boy with a sack over his head and shoulders like a hood, splashing through puddles.
Person 4: a couple sharing one patched umbrella (one figure group).
```

### A6 `LIFE__pass_night__sheet.png` — ночные прохожие

```text
Person 1: a night-shift worker with a small oil lamp, collar up, hurrying.
Person 2: a drunkard staggering, bottle in hand, singing with his head thrown back.
Person 3: a woman in a red shawl with a candle lantern, looking over her shoulder nervously.
Person 4: a hooded stranger walking quickly, face hidden (could be anyone).
```

### A7 `LIFE__pass_children__sheet.png` — дети

```text
Person 1: a barefoot boy running with a wooden toy rifle, pretending to be a monster hunter.
Person 2: a girl skipping with a rag doll.
Person 3: a newspaper boy with a satchel of blank broadsheets, one held up high (no text on them).
Person 4: two small children carrying a bucket together, water slopping out (one group).
```

### A8 `LIFE__pass_visitors__sheet.png` — гости сверху (редкие, контрастные)

```text
Person 1: a gentleman in a top hat and fur-collared coat holding a perfumed handkerchief to his nose, a hired
          bodyguard with a cudgel close behind him (one group).
Person 2: a veiled lady in mourning black with a parasol, a maid carrying her parcels (one group).
Person 3: a Lumen Collegium student in a gown with a satchel of books, wide-eyed, a little lost.
Person 4: a Rowan Exchange merchant in a brocade waistcoat counting coins into a purse as he walks.
```

## B. Местные персонажи — 10 листов, 20 лиц (чат «People — locals»)

У каждого — **имя (черновик, поменяй как хочешь), характер, распорядок и 4 позы**. В листе два персонажа:
слоты 1–4 — первый, 5–8 — второй. Позы по порядку: **1 идёт к нам · 2 идёт от нас · 3 действие A · 4 действие B
или особая поза**. Добавляй к каждому листу:

```text
Slots 1–4 are the same person in four poses, slots 5–8 are the second person in four poses. Inside each person the
face, clothes and colours are exactly the same in all four poses.
```

### B1 `LIFE__locals_1__sheet.png` — Слепой Тобиас и Матушка Грисл

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Слепой Тобиас**, скрипач | Тихий, добрый; вечером играет на Костровой площади, его пёс собирает монеты в шляпу. Ночью спит в нише у таверны | 1–2 идёт с поводырём-псом · 3 играет, смычок вверх · 4 смычок вниз |
| **Матушка Грисл**, торговка пирогами | Громкая, ругается, но подкармливает беспризорников; утром и днём ходит по рынку | 1–2 идёт с лотком · 3 кричит, подняв пирог · 4 протягивает пирог ребёнку |

```text
Person 1: blind Tobias, an old thin fiddler with milky white eyes, a long grey beard, a patched green coat, led by a
          shaggy grey dog on a string; slot 3 playing the fiddle with the bow up, slot 4 bow down.
Person 2: Mother Grisl, a huge red-faced pie-seller in a stained apron and a man's cap, a wide tray of steaming pies
          on a neck strap; slot 3 shouting with one pie raised, slot 4 bending to hand a pie to someone below.
```

### B2 `LIFE__locals_2__sheet.png` — Шустрый Пип и констебль Мэддок

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Шустрый Пип**, мальчишка-карманник | Ловкий, нахальный; трётся в толпе у барда и на рынке, после кражи удирает в Туманный лог | 1–2 крадётся · 3 тянет кошелёк из чужого кармана · 4 бежит со всех ног |
| **Констебль Мэддок**, ночной сторож | Толстый, ленивый, добродушный; дремлет на бочке у таверны, на свисток просыпается и бежит медленно | 1–2 бредёт с фонарём · 3 спит на бочке · 4 свистит в свисток, бежит |

```text
Person 1: Quick Pip, a skinny ten-year-old pickpocket in a huge flat cap and a ragged long coat; slots 1–2 sneaking,
          slot 3 reaching his hand towards someone's pocket, slot 4 running flat out with a purse.
Person 2: Constable Maddock, a fat good-natured night constable with a walrus moustache, a helmet, a bull's-eye
          lantern and a truncheon; slots 1–2 strolling, slot 3 asleep sitting on a barrel, slot 4 blowing a whistle
          and running heavily.
```

### B3 `LIFE__locals_3__sheet.png` — Мадам Вейл и фонарщик Олдрик

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Мадам Вейл**, гадалка | Таинственная; днём сидит в шатре на рынке, **ночью с фонарём уходит к Часовенному двору** (связана с культом?) | 1–2 идёт с фонарём · 3 сидит за хрустальным шаром · 4 раскладывает карты таро |
| **Олдрик**, фонарщик | Педант, вечно по расписанию; в сумерках обходит улицы и зажигает фонари один за другим, на рассвете гасит | 1–2 идёт с шестом и лесенкой · 3 зажигает фонарь · 4 сидит, курит трубку |

```text
Person 1: Madame Veil, a tall thin fortune teller in layered purple-grey shawls, many rings, a veil over her hair;
          slots 1–2 walking with a small red lantern, slot 3 sitting at a little table with a crystal ball, slot 4
          laying out tarot cards (the cards blank).
Person 2: Oldric the lamplighter, a neat wiry old man in a long brass-buttoned coat with a long brass pole and a small
          ladder; slots 1–2 walking, slot 3 standing on the ladder lighting a lamp, slot 4 sitting on the ladder smoking a pipe.
```

### B4 `LIFE__locals_4__sheet.png` — братья Корн и прачка Нэлл

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Братья Корн**, грузчики-близнецы (одна фигура) | Вечно спорят, кто несёт тяжелее; таскают бочки между рынком, таверной и депо | 1–2 несут бочку вдвоём · 3 бочка уронена, спорят · 4 сидят на бочке, пьют |
| **Нэлл**, прачка | Поёт, сплетничает со всеми; днём во дворах вешает бельё | 1–2 идёт с корзиной · 3 вешает простыню · 4 болтает, уперев руки в бока |

```text
Person 1: the Korn twins, two identical bald burly porters carrying one big barrel between them (one group); slots 1–2
          walking with it, slot 3 the barrel dropped and both arguing nose to nose, slot 4 both sitting on the barrel
          drinking from one bottle.
Person 2: Nell the washerwoman, a plump young woman with red forearms, a headscarf and rolled sleeves; slots 1–2 with a
          basket of wet laundry on her hip, slot 3 hanging a sheet on a line, slot 4 standing hands on hips, laughing.
```

### B5 `LIFE__locals_5__sheet.png` — старый охотник Хорн и сестра Агата

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Старый Хорн**, охотник на покое | На деревянной ноге; рассказывает детям у костра байки про тварей, иногда смотрит на героя и кивает | 1–2 ковыляет · 3 рассказывает, размахивая руками · 4 показывает огромный клык |
| **Сестра Агата**, Пепельная сестра | Строгая, быстрая; носит бинты и лекарства по дворам, ругает пьяниц | 1–2 идёт быстро с корзиной · 3 перевязывает руку (бинт в руках) · 4 грозит пальцем |

```text
Person 1: Old Horn, a retired monster hunter with a wooden leg, an eye patch, a scarred bald head and a battered long
          coat; slots 1–2 limping with a crutch, slot 3 telling a story with wide arm gestures, slot 4 holding up a huge fang.
Person 2: Sister Agatha, a brisk small Ash Sister nun in a grey habit with an ash mark on her forehead and a basket of
          bandages; slots 1–2 walking fast, slot 3 holding a bandage roll out as if bandaging someone, slot 4 wagging a finger sternly.
```

### B6 `LIFE__locals_6__sheet.png` — писарь Мортимер и инспектор Крейн

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Мортимер**, писарь Склепа-скриптория | Рассеянный; ходит, уткнувшись в книгу, роняет листы, ветер их разносит | 1–2 идёт, читая · 3 уронил бумаги · 4 ловит летящий лист |
| **Инспектор Крейн**, сыщик | Худой, внимательный, с трубкой; появляется у мест преступлений и там, где был слух | 1–2 идёт, руки за спиной · 3 присел с лупой · 4 пишет в блокноте |

```text
Person 1: Mortimer the scribe, a gangly young man with round spectacles, ink-stained fingers and a grey hooded robe,
          an armful of papers; slots 1–2 walking with his nose in an open book, slot 3 papers dropping from his arms,
          slot 4 jumping to catch a flying sheet.
Person 2: Inspector Crane, a lean sharp-faced detective in an Inverness cape and deerstalker with a curved pipe;
          slots 1–2 walking with hands behind his back, slot 3 crouching with a brass magnifier, slot 4 writing in a
          small notebook (pages blank).
```

### B7 `LIFE__locals_7__sheet.png` — Корвина и могильщик Ребб

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Корвина**, культистка Серого Причастия | Днём — обычная цветочница с серыми цветами; ночью в капюшоне рисует мелом знаки на мостовой | 1–2 идёт с корзиной серых цветов · 3 в капюшоне, рисует мелом на земле · 4 стоит со свечой, склонив голову |
| **Ребб**, могильщик | Угрюмый пьяница, разговаривает с воронами; копает днём, ночью сторожит кладбище | 1–2 идёт с лопатой на плече · 3 копает · 4 сидит на краю могилы с бутылкой, ворона на плече |

```text
Person 1: Corvina, a pale young woman with ash-grey hair; slots 1–2 a flower-seller with a basket of grey flowers in a
          plain shawl, slot 3 the same woman in a grey hood kneeling and drawing chalk circles on the cobbles, slot 4
          standing hooded with a grey candle, head bowed.
Person 2: Rebb the gravedigger, a gaunt unshaven man in a muddy coat and a battered hat; slots 1–2 with a spade on his
          shoulder, slot 3 digging, slot 4 sitting on the edge of a grave with a bottle and a crow on his shoulder.
```

### B8 `LIFE__locals_8__sheet.png` — механик Иззи и пророк Езекия

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Иззи**, подмастерье «Ржавой Шестерни» | Весёлая изобретательница; бегает за деталями, на улице запускает заводную игрушку — дети сбегаются | 1–2 бежит с шестернёй · 3 заводит латунную игрушку · 4 игрушка взорвалась облачком дыма, Иззи в саже |
| **Езекия**, уличный пророк | Безумный, кричит о конце света с ящика, звонит в колокольчик; прохожие обходят его | 1–2 бредёт с ящиком · 3 стоит на ящике, руки к небу · 4 звонит в колокольчик |

```text
Person 1: Izzy, a cheerful girl mechanic with goggles on her head, soot on her cheeks, rolled sleeves and a tool belt;
          slots 1–2 running with a big brass gear, slot 3 kneeling and winding a small brass clockwork beetle, slot 4
          the beetle burst in a puff of smoke and Izzy covered in soot, laughing.
Person 2: Ezekiel the street prophet, a wild-haired gaunt man in a sackcloth robe, barefoot; slots 1–2 carrying a
          wooden crate, slot 3 standing on the crate with arms raised to the sky, slot 4 ringing a hand bell.
```

### B9 `LIFE__locals_9__sheet.png` — крысолов Гумберт и чумной доктор

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Гумберт**, крысолов | Хвастун; с терьером и клеткой крыс на шесте, устраивает показ «как я их ловлю» | 1–2 идёт, клетка на шесте · 3 терьер прыгает на крысу · 4 гордо держит крысу за хвост |
| **Чумной доктор Дома Моррелл** (гость) | Молчаливый; осматривает дома, ставит мелом знак на двери — люди шарахаются | 1–2 идёт с тростью · 3 ставит мелом крест на двери · 4 осматривает больного, склонившись |

```text
Person 1: Humbert the rat-catcher, a boastful man with a big moustache, a waistcoat and a top hat with a rat tail on
          it, a pole with a cage of rats and a small fierce terrier; slots 1–2 walking, slot 3 the terrier leaping at a
          rat, slot 4 proudly holding a rat up by the tail.
Person 2: a House Morrell plague doctor in a long black waxed coat, wide hat and long beaked mask with a cane; slots
          1–2 walking, slot 3 drawing a chalk cross on a door, slot 4 bending over to examine someone below.
```

### B10 `LIFE__locals_10__sheet.png` — Пепельные воробьи и Серый незнакомец

| Кто | Характер и распорядок | Позы |
|---|---|---|
| **Пепельные воробьи**, банда детей (одна фигура: 3 ребёнка) | Носятся по кварталу, играют в «охотника и тварь», бегают за героем | 1–2 бегут гурьбой · 3 играют: один в плаще «охотник», другой в мешке «тварь» · 4 сидят на ступеньках, делят хлеб |
| **Серый незнакомец** | Высокий, в сером, лица не видно; **только ночью в тумане**, стоит и смотрит, исчезает, если подойти. Никто не знает, кто это | 1–2 медленно идёт · 3 стоит неподвижно, смотрит на нас · 4 полупрозрачный, тает в тумане |

```text
Person 1: the Ash Sparrows, three ragged children as one group; slots 1–2 running together, slot 3 playing "hunter and
          monster" — one in a cut-down coat with a stick rifle, one under a sack with paper claws, one cheering; slot 4
          sitting on steps sharing a loaf of bread.
Person 2: the Grey Stranger, a very tall thin figure in a long grey coat and grey wide hat, no face visible, only
          shadow; slots 1–2 walking slowly, slot 3 standing perfectly still, facing the viewer, slot 4 the same figure
          half-transparent, dissolving into fog.
```

## C. Группы — собраны ради дела (чат «People — groups»)

### C1–C2 Ходячие группы — 2 листа, 8 групп

Каждая группа — **одна картинка**, идёт по улице целиком. В промт вставляй SHEET, блок «Общее для всех ходячих»
и эту фразу, потом четыре группы из таблицы по порядку:

```text
Slots 1–2: group 1 (walking towards, walking away). Slots 3–4: group 2. Slots 5–6: group 3. Slots 7–8: group 4.
Each group is ONE picture; a group may use the full width of its slot, at the same figure scale as single people.
```

**`LIFE__groups_1__sheet.png`**

| Группа | Когда | Промт |
|---|---|---|
| Похоронная процессия | после смерти жителя, к кладбищу | A small funeral procession: four men carrying a plain coffin on their shoulders, a priest in front with a book, two mourning women behind. |
| Шествие культистов | полночь, к Часовенному двору | Six hooded Grey Communion cultists walking in a line, each holding a grey candle, the first carrying a pole with a hanging censer. |
| Охотники выходят на охоту | вечер, от таверны к краю района | Three hunters in long coats with rifles and lanterns, a big hound on a chain, a boy running alongside carrying a net. |
| Возвращение с охоты | рассвет, к мастерской | Two hunters pulling a handcart with a huge dark shape under a tarpaulin, one claw hanging out, children running behind. |

**`LIFE__groups_2__sheet.png`**

| Группа | Когда | Промт |
|---|---|---|
| Патруль Бдения | днём и ночью по главным улицам | Four Iron Vigil watchmen in dark iron half-armour marching in pairs, halberds on shoulders, an officer with a lantern in front. |
| Хор пьяниц | ночь, из таверны | Four drunk men arm in arm, swaying and singing, one holding a bottle up, one losing his hat. |
| Свадьба бедняков | праздник | A poor wedding procession: a bride in a plain white dress and a groom in a borrowed coat, a fiddler in front, three guests throwing paper flowers. |
| Погоня | после кражи | A shopkeeper in an apron and a constable with a truncheon running, both shouting, the shopkeeper waving a rolling pin. |

### C3 Группы на месте — 10 картинок

Блоки LIFE STYLE + SPRITE, холст **square**, `assets/ui/`. Стоят у места, игра «оживляет» покачиванием.
Общая часть: `A group scene that stands on the map, seen from high above at about 60 degrees, the group about the size of two houses.`
(Другие сценки у мест — концерт, торг, культ, лазарет, драка, преступление, похороны, картёжники, гадалка,
пушка — уже в [map-life.md](map-life.md), часть C; здесь — новые.)

| # | Файл | Где, когда | Промт |
|---|---|---|---|
| 1 | `LIFE__group__leaflet_readers.png` | столб листовок, утро | A crowd of people reading blank leaflets pinned on a tall post, one man reading aloud to illiterate neighbours, a child on someone's shoulders. |
| 2 | `LIFE__group__soup_kitchen.png` | лазарет, полдень | Ash Sisters ladling soup from a big iron cauldron over a fire into tin bowls, a long line of ragged people with bowls. |
| 3 | `LIFE__group__vigil_raid.png` | событие | Four Iron Vigil watchmen breaking down a door with a battering ram, a weeping woman held back, neighbours watching from windows. |
| 4 | `LIFE__group__bucket_brigade.png` | пожар | A chain of people passing water buckets hand to hand towards a smoking doorway, a man on a ladder throwing water. |
| 5 | `LIFE__group__street_circus.png` | рынок, вечер | A juggler with burning torches and a fire-eater blowing flame, a ring of amazed spectators, a hat on the ground. |
| 6 | `LIFE__group__roof_repair.png` | крыши, днём | Three workers on a sagging roof replacing slates, one on a ladder passing tiles up, a bucket of tar smoking. |
| 7 | `LIFE__group__rat_race.png` | двор у таверны | Men crouching around a chalk racing track on the ground where three rats run, betting with coins, one cheering wildly. |
| 8 | `LIFE__group__workers_meeting.png` | депо, вечер (перед бунтом) | Deepwright workers gathered around a man standing on a crate, fists raised, torches, angry faces. |
| 9 | `LIFE__group__wall_drill.png` | Кольцевая стена, утро | A sergeant drilling five young recruits with muskets on the wall walk, one recruit dropping his musket. |
| 10 | `LIFE__group__night_watch_fire.png` | ночь, у ворот | Three men warming their hands around a fire in an iron barrel, one telling a story, one asleep against the wall. |

## D. Маленькие сюжеты — что можно увидеть, если смотреть

Сюжеты собираются из картинок выше — **новых картинок не нужно**. Игра запускает их по времени и случайно.

| # | Сюжет | Как разыгрывается | Когда, где |
|---|---|---|---|
| 1 | **Карманник в толпе** | Тобиас играет → вокруг собираются прохожие → Пип крадётся в толпу, тянет кошелёк → кто-то кричит (значок-колокольчик) → Мэддок свистит → погоня (группа «Погоня») → Пип ныряет в Туманный лог или его ловят и уводит патруль | вечер, Костровая площадь |
| 2 | **Обход фонарщика** | Олдрик идёт от фонаря к фонарю, на каждом зажигается ореол; на рассвете — обратно, гасит | сумерки и рассвет |
| 3 | **Похороны** | Чумной доктор ставит крест на двери → на следующий день катафалк и похоронная процессия идут к кладбищу → Ребб копает | после «смерти» жителя / события |
| 4 | **Ночная тайна Мадам Вейл** | Ночью гадалка с фонарём идёт к Часовенному двору → у часовни Корвина рисует знак → шествие культистов → утром на мостовой остаётся меловой знак | полночь |
| 5 | **Охота** | Вечером отряд охотников выходит из таверны к краю района → на рассвете возвращается с телегой «туши» → дети и Хорн бегут смотреть → тележку везут к мастерской | после контракта героя или сама по себе |
| 6 | **Дождь** | Начался дождь → прохожие меняются на «дождевых», бегут под навесы → бард прячется → лужи с кругами → дождь кончился, всё возвращается | случайно |
| 7 | **Игрушка Иззи** | Иззи заводит жука → Воробьи сбегаются → жук взрывается дымком → дети разбегаются со смехом | днём, у мастерской |
| 8 | **Пророк и толпа** | Езекия на ящике → прохожие обходят его стороной → один пьяница спорит → Сестра Агата уводит пьяницу | днём, рынок |
| 9 | **Серый незнакомец** | В тумане ночью у лога стоит высокая фигура → если подвести к ней героя или камеру, она тает → на следующий день — новый слух | ночь, туман (редко) |
| 10 | **Тревога на стене** | Прожектор на башне шарит по туману → расчёт бежит к пушке → залп (вспышка, дым) → всё стихает | ночь, Дорожка над Бездной (редко) |
| 11 | **Облава** | Патруль Бдения марширует → облава у дверей → тюремный фургон увозит задержанного → соседи шепчутся (значок-глаз) | днём, после бунта или слуха |
| 12 | **Свадьба** | Скрипач ведёт свадьбу по улице → прохожие бросают цветы → у таверны танцы | праздник |

## E. Значки над головой — 1 лист (чат «People — groups»)

Игра ставит значок над жителем на 2–3 секунды: болтают, торгуются, испугались. Без букв и знаков препинания.
`LIFE__emote__sheet.png`, UI STYLE + TRANSPARENT (из [next-art-pack.md](next-art-pack.md)) + SHEET, холст wide.

```text
Eight small round speech-bubble icons of aged parchment with a thin dark outline, each with one simple symbol inside,
readable at 24 px:
1 a musical note (singing, music). 2 a gold coin (trade, money). 3 a small red heart (love, thanks).
4 a skull (death, fear). 5 a clenched fist (anger, fight). 6 a small brass bell with motion lines (alarm, a shout for help). 7 a candle flame (prayer, cult).
8 an open eye (watching, suspicion).
```

## F. Роли без имени и животные — 4 листа (чат «People — roles»)

Безымянные жители с ремеслом: их может быть несколько на карте сразу (в отличие от местных персонажей B).
Слоты одиночные (стоит и работает) или парами (towards, away), как указано.

### F1 `LIFE__roles_trade__sheet.png` — ремесло и улица

```text
1 a chestnut seller standing behind a small iron brazier cart, glowing coals, paper cones.
2 a candle seller with a wide tray of grey candles hanging from her neck, standing.
3 a butcher in a stained apron standing at a small stall with meat on iron hooks.
4 a beggar sitting against a wall with a tin cup, a blanket over the knees.
5 a rag-picker with a huge sack over the shoulder, walking towards.
6 the same rag-picker walking away.
7 a bill-poster with a bucket and brush pasting a blank notice on a wall.
8 a lookout leaning in a dark doorway, hat low, smoking.
```

### F2 `LIFE__roles_shadow__sheet.png` — тени

```text
1 a hooded Grey Communion cultist in grey robes holding a grey candle, walking towards.
2 the same cultist walking away.
3 a Scarlet Supper smuggler with a red scarf carrying a small crate, walking towards.
4 the same smuggler walking away.
5 a body-snatcher pushing a handcart with a shrouded body, walking towards.
6 the same body-snatcher walking away.
7 a chimney sweep standing on a roof ridge with brushes and a rope coil, soot-black face.
8 an alchemist standing and holding up a glowing green flask, examining it.
```

### F3 `LIFE__roles_guards__sheet.png` — стража и охотники

```text
1 two Iron Vigil watchmen in dark iron half-armour and helmets with halberds, side by side, walking towards (one group).
2 the same pair walking away.
3 a Ringwall guard in a long grey coat and steel helmet with a long musket on his shoulder, standing.
4 a Register surveyor standing at a brass tripod instrument, taking a measurement.
5 a Pale Hounds hunter with a fur collar and a big grey hound on a chain, walking towards.
6 the same hunter and hound walking away.
7 a Weavers hunter in a long coat with a weighted net over the shoulder, walking towards.
8 the same hunter walking away.
```

### F4 `LIFE__animals__sheet.png` — животные

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

## Где кого ставить и сколько

| Зона | Днём | Вечером и ночью | Свои персонажи |
|---|---|---|---|
| Пепельный квартал | рабочий люд, с ношей, пары, дети, торговцы | ночные прохожие, пьяницы, патруль, фонарщик | Грисл, Пип, Мэддок, братья Корн, Нэлл, Иззи, Езекия |
| Хибары на крышах | дети, трубочисты, ремонт крыши | контрабандисты, воришки | Воробьи |
| Часовенный двор | старики, паломники, писарь | культисты, шествие, Корвина | Мортимер, Корвина, Мадам Вейл (ночью) |
| Туманный лог | почти пусто | культист, похититель тел, **Серый незнакомец** | — |
| Нижние дворы | могильщик, сёстры, очередь за похлёбкой, рабочие депо | катафалк, ночной костёр у ворот | Ребб, Агата, Гумберт |
| Дорожка над Бездной | стража, муштра новобранцев | прожектор, расчёт пушки | — |
| Рынок и площадь (центр) | торговцы, читатели листовок, цирк | бард, драка, крысиные бега | Тобиас, Мадам Вейл (днём), Хорн |

Гости сверху (часть A8, чумной доктор, Крейн, учёные) — **редко**, их удобно привязать к событиям и контрактам.

## Вопросы владельцу

1. **Имена и характеры** персонажей B — черновики. Оставить, поменять, кого-то убрать? Заодно: некоторые сценки из
   [map-life.md](map-life.md) пересекаются с персонажами (концерт барда ↔ Тобиас, гадалка ↔ Мадам Вейл, сценка похорон ↔
   похоронная процессия) — оставить обе версии (стоящую и ходячую) или одну?
2. **Сколько людей сразу:** ~20 (мрачно и тихо), ~40 (живо) или ~60 (шумные трущобы)?
3. **Сюжеты из части D** — какие нравятся? Нужно ли, чтобы некоторые давали что-то герою (слух от Хорна, Пип крадёт
   монеты, Серый незнакомец = новый слух), или пусть будут только для атмосферы?
4. **Местные персонажи — постоянные?** Если кто-то из них может погибнуть или исчезнуть (после событий района), мир
   станет «живее», но это уже механика.
