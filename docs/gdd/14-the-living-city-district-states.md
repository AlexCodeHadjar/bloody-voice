# 14. The Living City: District States

Districts and specific areas **change their appearance and rules** because of story, world events and the hero's actions. A change is a **state** — data, not code. Any district, area or landmark can be in exactly one state at a time; states can be temporary (timed) or permanent (a 'scar' on the city).

## 14.1 Granularity

| Level | Example | What can change |
|---|---|---|
| District | NORDHAL | Map tile art, colour grade, ambient sound, monster pool, rumor tag weights, shop modifiers, danger rank |
| Area | NORDHAL/tavern_street | Area icon and overlay on the map, which locations are open, rumor spawn points |
| Landmark | NORDHAL/tavern | Landmark art and its function (e.g. tavern closed during a riot) |

## 14.2 State catalog

| State | Type | Look (art change) | Rules change |
|---|---|---|---|
| normal | default | Base art | Base values |
| fog_breach | timed 3–7 days | Grey fog overlay, dimmed lamps, cracked wall | Dreamspawn pool, danger +1 rank, Ringwall contracts |
| flooded | timed (storm season) | Water overlay on low areas, boats, sandbags | Some areas closed; water creatures; search ring grows slower |
| burning → burned | event → permanent | Fire, then black ruins | Shop closed; scavenging gives more Scrap |
| rebuilding → rebuilt | timed → permanent | Scaffolding, then a NEW look (different from the original) | New landmark may appear |
| quarantine | timed | Barricades, plague doctors, chalk marks | Entry needs a pass or reputation; medical contracts |
| riot | timed | Barricades, smoke, broken windows | Faction conflict contracts; prices up; tavern may close |
| martial_law | timed | Iron Vigil patrols, banners, checkpoints | Safer (danger −1), black market hidden |
| festival | timed (Dusk Night, Moon Feast) | Lanterns, bonfires, garlands | Rumors are noisier; prices up; special event contracts |
| eclipse | story (Silverhill) | Black-silver sky, inverted moon windows | Masked Moon story fights |
| collapsed | story, permanent | Part of the platform fell; a hole into the Transition Zone | Opens a new path down; area removed |
| cleansed | after the hero clears a threat | Brighter grade, people on the streets | Danger −1, cheaper shop, reputation + |

## 14.3 How a state changes

1. A **trigger** fires: story step, world event, a deadline missed, a contract completed, a faction reaching a reputation tier.
2. `DistrictStateRules.apply(state, target, new_state, duration)` updates `RunState.city` (pure data). Saves keep it.
3. The rule emits `EventBus.district_state_changed(target, old, new)`.
4. The map view listens and plays a **transition** (cross-fade between art variants + particle overlay), then shows a short news leaflet ('Storm floods the Laundry Canals').
5. Timed states count down on day change and return to the previous or a follow-up state (burning → burned).

## 14.4 Data example

```text
// data/city/district_states.json  (catalog: what a state does)
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
}
```

## 14.5 Art rules for variants

- Every district has a **base** art and up to 4 **variants** that are actually used by that district (not every state for every district).
- Variants **keep the exact composition, camera and silhouettes** of the base image; only lighting, overlays and damage change. This makes cross-fades seamless.
- File naming: `<CODE>__<state>.webp` for districts, `<CODE>__<area>__<state>.webp` for areas.
- If a variant image is missing, the game falls back to base art + overlay scene + colour grade (so content can ship before art).

| District | Planned variants |
|---|---|
| CROWN | riot, martial_law, festival |
| SILVERHILL | eclipse, festival, quarantine |
| VIGIL | martial_law |
| LUMEN | quarantine, burning → burned |
| MARKET | festival, burning → burned → rebuilt |
| EXCHANGE | fog_breach |
| AVENUES | flooded, quarantine, cleansed |
| MORRELL | quarantine |
| NORDHAL | riot (Hound War), festival (Dusk Night) |
| GREY | fog_breach, riot, cleansed |
| DEEPWRIGHT | collapsed (story), riot |
| SCARLET | martial_law, burning → burned |
| WALL | fog_breach |
