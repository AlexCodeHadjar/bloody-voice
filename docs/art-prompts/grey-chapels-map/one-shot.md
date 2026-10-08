# Карта Серых Часовен — всё в одном (для нового чата)

Этот файл — чтобы запустить генерацию карты района в **новом чате ChatGPT** с нуля, одним сообщением.
Полная пошаговая версия с кусками карты — [README.md](README.md).

## Что сделать

1. Открой новый чат.
2. Приложи **одну картинку** — лист со всеми эталонами:
   - у тебя на компьютере: `assets/refs/GREY_reference_sheet_full.png` — с твоими образцами стиля (лучше эту);
   - в репозитории: `docs/art-prompts/grey-chapels-map/for-gpt/reference_sheet.png` — то же без образцов стиля.
3. Скопируй **всё сообщение** из блока ниже и отправь.
4. Проверь результат по списку в конце файла. Если что-то не так — отправь в тот же чат нужный FIX.
5. Сохрани удачный вариант как `assets/district_maps/GREY__overview.png` и пришли мне.

Что на листе: **P** — план района с номерами мест, **S** — разрезы сбоку (внутри свои маленькие A–D),
**L** — где район в городе, **H** — одобренный Сломанный подъёмник, **R1–R3** — образцы стиля.

## Сообщение для ChatGPT

```text
Create one image: a portrait 2:3 top-down city map of a single slum district called the Grey Chapels.
Everything you need is on the ONE attached reference sheet. Its panels are marked:
P = the plan of the district (outline, streets, rows of houses, numbered landmarks 1–21; diagonal hatching =
neighbouring districts, paint them as normal houses, never as stripes);
S = side views explaining heights (A: Candle Bridge over the sunken gully, B: the aqueduct, C: the Ringwall,
D: the district borders);
L = where the district lies in the whole city;
H = the approved look of landmark 18 — copy it exactly;
R1–R3 = style references (street-level photos/paintings): take ONLY their colours, rain, wet materials and
light, never their camera angle.
Draw no text, no letters, no numbers, no panel letters, no legend, no frame.

STYLE: realistic painterly concept art of a Victorian slum at night after rain, like a matte painting for a
dark detective game. Desaturated cold palette: wet slate grey, soot black, blue-grey fog, dark brick brown;
small warm amber points of gas lamps and lit windows; no bright colours, no saturated roofs. Wet glistening
slate roofs and cobbles, puddles reflecting lamplight, chimney smoke, low fog in alleys. Crooked, cramped,
patched with planks; grime, moss, washing lines. No ink outlines, no watercolour, no cartoon, no
tabletop / board-game map look.

CAMERA: straight down from above, like a photo from a balloon, north up. Only a very slight perspective:
buildings never lean over the streets, no facades. A house is about as wide as a street. Every house has its
own roof and chimneys. People, if any, are tiny dark dots.

LAYOUT: follow plan P for the outline, the street network, which buildings face which streets and where each
numbered landmark is. The plan's straight lines are schematic — make the streets slightly winding, keep every
connection. The plan is 3:4; fit all of it and fill the extra top and bottom with neighbouring roofs.

BORDERS (very important):
- There is NO wall around the district and NO wall between districts.
- North: a cobbled boundary street; across it the brick houses and warm forge glow of the Nordhal quarter.
- West: a raised tram embankment with two rails and a level crossing (20); across it the glass roofs and faint
  green light of Lumen Campus and the market roofs of Rowan Market. The tram line ENDS in the south-west corner
  in a TRAM DEPOT (21): three long engine sheds, tracks fanning into them, a small turntable, a coal heap, one old
  tram car. The rails stop there; they never continue along the south and never turn into a road.
- South: an old brick viaduct on arches carrying a ROAD (no rails), lower and plainer than the aqueduct so the
  two never look alike; one arch is a tunnel closed by a wooden barricade (19); beyond it Deepwright industry smoke and the red lanterns of Scarlet Row.
- East: the RINGWALL — a massive fortress wall of dark stone, as thick as three houses side by side and three
  times taller than them, curving down the whole right side and running on beyond the top and bottom edges of the
  image (it is a ring round the whole city): a walkway with crenellations on top, big square
  towers, its inner face in deep shadow casting a dark band onto the street below. At its inner foot a narrow
  railed ledge with lamps on chains (the Edge Walk, 14). Beyond the wall only a sea of grey fog (the abyss).
  Nothing is built on the wall or merges into it (except the Broken Hoist 18 and the Edge Walk ledge); it must
  read clearly as a huge wall, not a road or a kerb.
- Neighbouring districts are complete and tidy; their houses stop at their side of the border and never cross it.

HEIGHTS (side views S):
- Fog Hollow: a long narrow sunken gully two storeys below the streets, running south from the centre and
  bending east, steep stone retaining walls, grey fog lying in it like water. Not a round hole.
- 10 Candle Bridge: a short stone bridge AT STREET LEVEL across the gully's narrow northern neck, hundreds of
  small candles on its parapets.
- 15 Old Aqueduct: a brick viaduct with tall arched openings from the gully to the Ringwall, a railed walkway on
  top, yards and shacks seen through the arches, a long shadow across the roofs to the south-east.

LANDMARKS (numbers on plan P):
1 the Old Grey Chapel: a large Gothic church of grey stone, cross-shaped; its west arm has lost its roof (bare
  timber ribs, the dark nave visible from above); a square tower at its north end; a walled yard to the east with
  toppled statues and grey candles. 2 a very tall thin bell tower with scaffolding and a lantern on top, casting
  a long shadow. 3 an iron gate in a brick arch on the northern boundary street. 4 Ash Market: patched canvas
  stalls round three bright bonfires. 5 a crooked junk shop with a scrap cart and hanging bones. 6 the Lantern &
  Hook tavern: wide and low, a big iron lantern and a hunter's hook over the door, every window lit. 7 the hero's
  home: a narrow tenement, one lit garret window, an outside iron stair. 8 a brick workshop with a huge rusty cog
  over its yard gate, sparks from the chimney. 9 Bonfire Square: where the streets meet, one big bonfire and a tall
  post covered with paper leaflets. 11 stairs down into the gully to half-flooded cellar doors. 12 a crypt entrance
  south of the chapel with a lit reading lamp. 13 a huge hooded face carved into the inner face of the Ringwall,
  candles and offerings below. 16 an infirmary with white sheets in the windows and a red lamp. 17 a walled paupers'
  graveyard, crooked wooden markers, open graves. 18 the Broken Hoist at the south-east corner exactly as in H: a
  tall timber-and-iron lift tower on the Ringwall leaning out over the abyss, big pulley wheels, snapped cables
  hanging into the fog. 21 the tram depot (see BORDERS).
North-east: shacks built on top of older roofs, linked by rope bridges and ladders.
Everywhere else: houses packed wall to wall in rows along the streets, small back yards, chimney smoke, gas lamps
along the main streets, a few small fires in yards.
```

## Проверка результата и исправления

| Если видишь | Отправь в тот же чат |
|---|---|
| Стену вокруг района или между районами | `Remove every wall around the district and between districts. Only the Ringwall on the east is a wall; the other edges are a street (north), the tram embankment (west), a road viaduct (south). Keep everything else the same.` |
| Стена тонкая, похожа на дорогу; дома на ней или слились с ней | `Make the Ringwall a massive fortress wall: as thick as three houses, three times taller, crenellated walkway on top, big square towers, inner face in deep shadow, grey fog beyond its outer edge. Nothing is built on it; houses keep one street away. Only the carved face 13, the Edge Walk 14 and the Broken Hoist 18 stay on it. Keep everything else the same.` |
| Рельсы идут дальше по югу или превращаются в дорогу, нет депо | `The tram line must END in the south-west corner in a tram depot: three long sheds, tracks fanning in, a turntable, a coal heap. Remove rails from the south viaduct; it carries a road only. Keep everything else the same.` |
| Круглая дыра с мостом, мост в никуда, акведук без арок | `The Candle Bridge is a short stone bridge at street level across a long narrow sunken gully full of fog (side view S-A). The aqueduct is a brick viaduct with tall arched openings and a long shadow (S-B). Keep everything else the same.` |
| Вид наклонён, как с улицы | `Look straight down at the roofs like a photo from a balloon; no facades, buildings do not lean. Use R1–R3 only for colour, rain and light.` |
| Яркие крыши, контуры, «настольная игра» | `Keep the camera and layout; repaint only the style: realistic painterly wet night, desaturated grey, glistening roofs, fog, small warm lamp lights. No ink outlines.` |
| Подъёмник 18 не такой | `Redraw landmark 18 exactly like panel H. Keep everything else the same.` |

## Проверяющий

**Лучше всего — у Claude.** Сохрани картинку (например, в `assets/district_maps/`) и напиши мне «проверь карту
<путь>». Субагент `map-checker` сравнит её с планом, разрезами, одобренным подъёмником и твоими образцами стиля,
проверит 8 правил, найдёт недостающие места, оценит красоту и стиль и выдаст **готовые английские сообщения**
для ChatGPT (не больше двух за раз).

**Быстрая самопроверка внутри ChatGPT** — после каждой картинки отправь в тот же чат:

```text
Now act as a strict art reviewer. Do NOT generate an image yet. Compare your last image with the attached
reference sheet (P plan, S side views, H hoist, R1–R3 style) and answer as a checklist:
1) No wall around the district or between districts? 2) Ringwall massive (three houses thick, crenellations,
towers, shadow), nothing built on it except the hoist 18? 3) Tram rails end in the depot 21, no rails on the south
viaduct? 4) Narrow fog gully with the Candle Bridge at street level? 5) Brick aqueduct with arches and shadow?
6) Neighbour houses tidy, not crossing the border? 7) Top-down, no facades? 8) No text anywhere?
9) Which landmarks 1–21 are missing or unrecognisable? 10) Does landmark 18 match panel H?
11) Style vs R1–R3 (palette, wet roofs, fog, warm lamps) — score 0–10. 12) Beauty and readability — score 0–10.
Then list at most two concrete fixes, most important first, and wait for my "go".
```

Когда ответит — напиши «go», и он исправит. Его самопроверка мягче, чем у Claude: он склонен хвалить
собственную картинку, поэтому финальную версию всё равно присылай мне.
