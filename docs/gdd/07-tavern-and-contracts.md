# 7. Tavern and Contracts

## 7.1 The contract board

- The tavern 'The Lantern & Hook' (in the Grey Chapels, GDD §20) has a **wooden wall with pinned leaflets**: reward, short description, black silhouette.
- Clicking a leaflet opens the **contract tablet** in front of the hero. Arrows left/right switch between tablets.
- **Accept** stamps a seal on the leaflet (the hunter has taken the job). The contract moves to the **tracker** in the top-right corner.
- Tracker row: monster silhouette, name, days left, **region icon**. Clicking the icon plays a glowing outline animation of the region where the creature was last seen.

## 7.2 Contract tablet

| Field | Value |
|---|---|
| Petition | Who asks and why (in-world letter text) |
| Type | Slay / Capture / Research / Story |
| Silhouette | Black outline of the creature (can be partial or wrong if witnesses lied) |
| Known signs | 2–3 known tags (sound, trace, victims, time, place, shape) |
| Last seen | District (and area) with a region icon |
| Deadline | Days |
| Reward | Money, XP, reputation, sometimes a blueprint |
| Expected danger | Register rank A / P / D / S |

## 7.3 Contract types

| Type | Goal | Notes |
|---|---|---|
| Slay | Kill the target | Base type. Trophies from broken body parts. |
| Capture | Bring the creature alive | Contract-only capture consumables are issued. Higher reward and a pure blood sample if kept. |
| Research | Observe the creature in combat | Play 'Observe' on N body parts and survive N turns. Low money, big Bestiary gain. |
| Story | Chapter progression | Authored, may contain dialogue choices and special fights. |

## 7.4 How it works now (Phase 3 step 1, owner 2026-10-12)

| Rule | Value |
|---|---|
| Where | The board hangs in the Lantern & Hook (Grey Chapels, place 6 on the district map, action `tavern`); the tracker sits in the top-right corner of the district screen, the place card opens below it. |
| Board | Every Monday (and at a new game / on loading a save from an earlier week) 3–5 leaflets on creatures that live in the hero's district (`monsters[].districts`; GREY: Gutter Choir, Lamplighter, Vigil Hound, Burrow Wyrm). Leaflets nobody took go on Monday; taken ones stay in the tracker. |
| Types now | Slay and Capture (Research and Story come later). Capture: the fight gets an iron net; only a captured creature counts. Slay: slain or captured. |
| Leaflet | Type icon, rank badge, black silhouette, creature name, reward, days left; a wax seal once taken. |
| Tablet | Petition (who asks + letter, `data/contracts/petitions.json`), type, rank, silhouette, 2–3 known signs (tags with category icons, `data/contracts/tags.json`), last seen (a zone of the district map), deadline, reward; arrows; «Принять заказ». |
| Limits | At most 3 open contracts; 2 leaflets on one creature per board. |
| Reward | Money (XP since Phase 6 step 1; reputation and rank effects — GDD 12.2): by the creature's rank A 30 / P 50 / D 80 / S 130, ±20 %, ×1.5 for a capture, rounded to 5. |
| Deadline | 4–10 days. **Overdue: the contract stays, the creature is stronger (hp ×1.25, +1 damage per hit), the reward does not grow** (owner). Shown red in the tracker and on the fight's top bar. |
| Region icon | Makes the zone where the creature was last seen glow blue on the district map; the camera glides there. |
| Rumors (step 2) | A taken contract seeds a true rumor diamond at once and then every 2–3 days (GDD 8.4). Any fight with a contract's creature counts for the contract with the nearest deadline. |

Numbers: `balance.json → contracts`. Code: `core/generation/contract_generator.gd`, `core/rules/contracts/contract_rules.gd`,
`core/state/contracts_state.gd`, screens `scenes/contracts/`.
