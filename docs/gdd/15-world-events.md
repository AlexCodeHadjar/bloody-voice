# 15. World Events

| Event | When | Districts | Effect |
|---|---|---|---|
| Storm Season | Chapter I, week 3 (story) | AVENUES, SCARLET, low areas | flooded state; water creatures; a cursed artifact washes up (story hook) |
| Dusk Night | End of Chapter I | NORDHAL, SILVERHILL | festival; the Dusk Anointed appear; special contracts |
| The Lumen Register | End of each chapter | City-wide | Hero rank recalculated; recap leaflet |
| Fog Breach | Random, 1 per chapter | WALL + adjacent district | fog_breach; dreamspawn; defence contracts |
| The Hound War | Chapter II | NORDHAL | riot; choose Pale Hounds or Weavers |
| Uprising Below | Chapter II | DEEPWRIGHT, GREY, Transition | riot; lifts locked; Grey Communion choice |
| The Fall of Shaft 7 | Chapter II (story) | DEEPWRIGHT | collapsed — permanent; opens a new way down |
| Grey Plague Scare | Random | MORRELL, AVENUES, GREY | quarantine |
| The Masked Moon | Chapter III | SILVERHILL | eclipse; final Pale Vault fight |

Random events are drawn from a weighted, seeded table so every playthrough feels different, but story events are fixed.

## 15.1 How it works now (Phase 7, owner 2026-10-12: random by weeks, the Grey Chapels only)

| Rule | Value |
|---|---|
| Table | `data/city/events.json`: Fog Breach (fog_breach, weight 3, 3–6 days), Grey Plague Scare (quarantine, 2, 4–6), Dusk Night (festival, 2, 2–3) — district GREY. |
| Roll | Each Monday (`EventRules.weekly`, stream `events` by week): none before week 2, none while one is on or in the rest week after one ended; then a 50 % chance, weighted pick. A save loaded mid-week waits for Monday. The roll comes before the board, so rewards of the week's leaflets follow the state. |
| News | The morning leaflet («Новости»: the event picture `EVENT__art__<id>`, the news, what the state changes) when an event starts and when it ends; shown on the district screen, one after another, after any open panel. |
| Later | Story events at fixed weeks, events of other districts, events from the hero's deeds. |
