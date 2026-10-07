// Part 2 — the city, dynamic districts, events
const fs = require("fs");
const path = require("path");
const A = (f) => path.join(process.env.BV_ASSETS || "assets", f);
const { H1, H2, H3, P, Bul, Num, Note, Code, Mono, Tbl, KV, Img } = require("./lib");
const { DISTRICTS, LOWER } = require("./data_city");

const intro = () => [
  H1("13. The City of Hallowdeep"),
  H2("13.1 Overview"),
  Bul([
    "Hallowdeep is the capital of a land sealed by the **Mistveil** — a wall of living fog raised long ago by the **Four Elder Mothers** to keep the **Underdream** and its **dreamspawn** out. Cracks in the Mistveil let creatures through; that is why hunters exist.",
    "The city is built **on the ruins of an ancient royal capital**.",
    "The **Upper City** is an artificial city of metal on a huge round platform, separated from the ground and enclosed by the **Ringwall** with three gates.",
    "Streets near the centre have names; the rest are numbered ('4th Avenue', 'Street K').",
    "Under the platform lie the **Transition Zone** and the **Lower City** (levels 6 → 1), isolated for centuries after the Grey Plague. The deeper the level, the stronger the mutation: levels 6–5 are still human, level 4 shows bodily mutation, level 3 dwellers no longer consider themselves human.",
    "Technology looks like the 1880s–1890s, but mechanics and biotechnology are far ahead: lifts, trams, electric searchlights, artificial humans.",
    "The only official government is the **Crown Magistracy** in the Crown Ward, and it is weakening. Powerful organisations (Collegium, Iron Vigil, Rowan Exchange, Deepwright) are tolerated while they are useful.",
  ]),
  H2("13.2 Vertical layers"),
  ...Img(A("city_cross_section.png"), 540, "Figure 2 — Cross-section of Hallowdeep (docs/assets/map/city_cross_section.png)"),
  Tbl(["Layer", "Opens in", "Short description"], [
    ["Upper City", "Prologue / Chapter I", "12 districts on the metal platform inside the Ringwall."],
    ...LOWER.map((l) => [l[0], l[1], l[2]]),
  ], [1.2, 1, 3.5]),
];

const mapPage = () => [
  ...Img(A("city_sketch.png"), 860, "Figure 1 — Hallowdeep Upper City: district sketch, north is up (docs/assets/map/city_sketch.png)"),
];

const afterMap = () => {
  const grid = fs.readFileSync(A("city_grid.txt"), "utf8").split(/\r?\n/);
  const start = grid.findIndex((l) => l.startsWith("~"));
  const end = grid.findIndex((l, i) => i > start && l.trim() === "");
  return [
    H2("13.3 How to read the sketch"),
    Bul([
      "**Top-down view, north is up.** The large circle is the metal platform; the dark ring is the **Ringwall**; the grey noise outside is the **Mistveil** (fog wasteland, not walkable).",
      "**Crown Ward** sits in the exact centre and is the highest point. Around it is the **inner ring** (Silverhill inner part, Vigil Spire Ward, Lumen Campus, Rowan Market, Morrell Ward, the inner Avenues).",
      "The **outer ring** runs to the wall: Silverhill (north-west), Nordhal Quarter (north-east), Grey Chapels (east), Deepwright Lifts (south-east), Scarlet Lantern Row (south), the Numbered Avenues (the whole west and south-west).",
      "Three **gates**: Hawk Gate (north), Wolf Gate (south-east), Bear Gate (south-west). Each gate has a Rowan Exchange post; together they form a **triangle** around the Crown Ward.",
      "The **dashed ring** is the tram line between inner and outer rings. **Black discs** in the south-east are lift shafts going down. **Grid lines** mark the numbered streets of the Avenues.",
      "**Red numbers** are landmarks (legend on the right side of the sketch).",
      "Districts are deliberately of **different sizes and shapes**: the Avenues are the biggest, the Vigil Spire Ward is a small wedge, the Exchange posts are tiny enclaves.",
    ]),
    H2("13.4 ASCII grid (for ChatGPT and for code)"),
    P("The same layout sampled as a text grid. Each cell is printed as two characters so it looks square in a monospace font. Two-digit numbers are landmarks. File: `docs/assets/map/city_grid.txt` — attach it together with the PNG when asking ChatGPT for art."),
    ...Mono(grid.slice(start, end), 14),
    P(" "),
    Tbl(["Symbol", "District", "Symbol", "District"], [
      ["C", "Crown Ward", "N", "Nordhal Quarter"],
      ["S", "Silverhill", "G", "Grey Chapels"],
      ["V", "Vigil Spire Ward", "D", "Deepwright Lifts"],
      ["L", "Lumen Campus", "R", "Scarlet Lantern Row"],
      ["M", "Rowan Market", "X", "Rowan Exchange Posts"],
      ["A", "Numbered Avenues", "#", "The Ringwall"],
      ["H", "Morrell Ward", "~", "Mistveil (outside)"],
    ], [0.5, 2, 0.5, 2]),
    H2("13.5 District catalog"),
    P("Each district is described with the same fields. **Code** is the stable identifier used in data files, saves and art file names (e.g. `art/city/districts/NORDHAL__normal.webp`)."),
    ...DISTRICTS.flatMap((d) => [
      H3(`${d.name}  [${d.code} · ${d.char}]`),
      KV([
        ["Class / size", `${d.cls} — ${d.size}`],
        ["Position", d.where],
        ["Controlled by", d.controller],
        ["Danger rank", d.danger],
        ["Look", d.look],
        ["Areas (sub-zones)", d.areas.join(" · ")],
        ["Landmarks", d.landmarks],
        ["Typical monsters", d.monsters],
        ["Rumor flavour tags", d.tags],
        ["Gameplay role", d.role],
      ]),
    ]),
    H2("13.6 The Lower City and the Ruins"),
    Tbl(["Layer", "Chapter", "Description"], LOWER.map((l) => [l[0], l[1], l[2]]), [1.2, 1, 4]),
    Note("The Lower City is not just 'the enemy'. The Grey Communion is an ally with a different truth: the people below hate the Upper City for centuries of oppression. This is a key story choice in Chapter II."),

    // ------------------------------------------------------------ 14
    H1("14. The Living City: District States"),
    P("Districts and specific areas **change their appearance and rules** because of story, world events and the hero's actions. A change is a **state** — data, not code. Any district, area or landmark can be in exactly one state at a time; states can be temporary (timed) or permanent (a 'scar' on the city)."),
    H2("14.1 Granularity"),
    Tbl(["Level", "Example", "What can change"], [
      ["District", "NORDHAL", "Map tile art, colour grade, ambient sound, monster pool, rumor tag weights, shop modifiers, danger rank"],
      ["Area", "NORDHAL/tavern_street", "Area icon and overlay on the map, which locations are open, rumor spawn points"],
      ["Landmark", "NORDHAL/tavern", "Landmark art and its function (e.g. tavern closed during a riot)"],
    ], [0.8, 1.4, 4]),
    H2("14.2 State catalog"),
    Tbl(["State", "Type", "Look (art change)", "Rules change"], [
      ["normal", "default", "Base art", "Base values"],
      ["fog_breach", "timed 3–7 days", "Grey fog overlay, dimmed lamps, cracked wall", "Dreamspawn pool, danger +1 rank, Ringwall contracts"],
      ["flooded", "timed (storm season)", "Water overlay on low areas, boats, sandbags", "Some areas closed; water creatures; search ring grows slower"],
      ["burning → burned", "event → permanent", "Fire, then black ruins", "Shop closed; scavenging gives more Scrap"],
      ["rebuilding → rebuilt", "timed → permanent", "Scaffolding, then a NEW look (different from the original)", "New landmark may appear"],
      ["quarantine", "timed", "Barricades, plague doctors, chalk marks", "Entry needs a pass or reputation; medical contracts"],
      ["riot", "timed", "Barricades, smoke, broken windows", "Faction conflict contracts; prices up; tavern may close"],
      ["martial_law", "timed", "Iron Vigil patrols, banners, checkpoints", "Safer (danger −1), black market hidden"],
      ["festival", "timed (Dusk Night, Moon Feast)", "Lanterns, bonfires, garlands", "Rumors are noisier; prices up; special event contracts"],
      ["eclipse", "story (Silverhill)", "Black-silver sky, inverted moon windows", "Masked Moon story fights"],
      ["collapsed", "story, permanent", "Part of the platform fell; a hole into the Transition Zone", "Opens a new path down; area removed"],
      ["cleansed", "after the hero clears a threat", "Brighter grade, people on the streets", "Danger −1, cheaper shop, reputation +"],
    ], [1.1, 1.1, 2, 2.2]),
    H2("14.3 How a state changes"),
    Num([
      "A **trigger** fires: story step, world event, a deadline missed, a contract completed, a faction reaching a reputation tier.",
      "`DistrictStateRules.apply(state, target, new_state, duration)` updates `RunState.city` (pure data). Saves keep it.",
      "The rule emits `EventBus.district_state_changed(target, old, new)`.",
      "The map view listens and plays a **transition** (cross-fade between art variants + particle overlay), then shows a short news leaflet ('Storm floods the Laundry Canals').",
      "Timed states count down on day change and return to the previous or a follow-up state (burning → burned).",
    ]),
    H2("14.4 Data example"),
    Code(`// data/city/district_states.json  (catalog: what a state does)
{
  "flooded": {
    "art_suffix": "flooded",              // art/city/districts/AVENUES__flooded.webp
    "overlay": "water_low",               // optional particle/overlay scene
    "danger_delta": 0,
    "closed_areas": ["laundry_canals"],
    "monster_pool_add": ["gutter_choir"],
    "rumor_tag_weights": { "near_water": 2.0, "rain": 2.0 },
    "ring_growth_mult": 0.5,
    "shop_price_mult": 1.1
  }
}

// RunState.city  (save data: where each state currently is)
{
  "districts": {
    "AVENUES": { "state": "flooded", "days_left": 4, "next": "normal" },
    "GREY":    { "state": "normal" }
  },
  "areas":     { "NORDHAL/tavern_street": { "state": "riot", "days_left": 2 } },
  "landmarks": { "NORDHAL/tavern": { "state": "closed" } },
  "scars":     ["DEEPWRIGHT/shaft_7:collapsed"]
}`),
    H2("14.5 Art rules for variants"),
    Bul([
      "Every district has a **base** art and up to 4 **variants** that are actually used by that district (not every state for every district).",
      "Variants **keep the exact composition, camera and silhouettes** of the base image; only lighting, overlays and damage change. This makes cross-fades seamless.",
      "File naming: `<CODE>__<state>.webp` for districts, `<CODE>__<area>__<state>.webp` for areas.",
      "If a variant image is missing, the game falls back to base art + overlay scene + colour grade (so content can ship before art).",
    ]),
    Tbl(["District", "Planned variants"], [
      ["CROWN", "riot, martial_law, festival"],
      ["SILVERHILL", "eclipse, festival, quarantine"],
      ["VIGIL", "martial_law"],
      ["LUMEN", "quarantine, burning → burned"],
      ["MARKET", "festival, burning → burned → rebuilt"],
      ["EXCHANGE", "fog_breach"],
      ["AVENUES", "flooded, quarantine, cleansed"],
      ["MORRELL", "quarantine"],
      ["NORDHAL", "riot (Hound War), festival (Dusk Night)"],
      ["GREY", "fog_breach, riot, cleansed"],
      ["DEEPWRIGHT", "collapsed (story), riot"],
      ["SCARLET", "martial_law, burning → burned"],
      ["WALL", "fog_breach"],
    ], [1, 4]),

    // ------------------------------------------------------------ 15
    H1("15. World Events"),
    Tbl(["Event", "When", "Districts", "Effect"], [
      ["Storm Season", "Chapter I, week 3 (story)", "AVENUES, SCARLET, low areas", "flooded state; water creatures; a cursed artifact washes up (story hook)"],
      ["Dusk Night", "End of Chapter I", "NORDHAL, SILVERHILL", "festival; the Dusk Anointed appear; special contracts"],
      ["The Lumen Register", "End of each chapter", "City-wide", "Hero rank recalculated; recap leaflet"],
      ["Fog Breach", "Random, 1 per chapter", "WALL + adjacent district", "fog_breach; dreamspawn; defence contracts"],
      ["The Hound War", "Chapter II", "NORDHAL", "riot; choose Pale Hounds or Weavers"],
      ["Uprising Below", "Chapter II", "DEEPWRIGHT, GREY, Transition", "riot; lifts locked; Grey Communion choice"],
      ["The Fall of Shaft 7", "Chapter II (story)", "DEEPWRIGHT", "collapsed — permanent; opens a new way down"],
      ["Grey Plague Scare", "Random", "MORRELL, AVENUES, GREY", "quarantine"],
      ["The Masked Moon", "Chapter III", "SILVERHILL", "eclipse; final Pale Vault fight"],
    ], [1.2, 1.3, 1.6, 2.6]),
    P("Random events are drawn from a weighted, seeded table so every playthrough feels different, but story events are fixed."),
  ];
};

module.exports = { intro, mapPage, afterMap };
