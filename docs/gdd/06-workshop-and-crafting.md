# 6. Workshop and Crafting

Screen layout: GDD §23.1.

## 6.1 Resources

| Icon | Resource | Main sources | Used for |
|---|---|---|---|
| Gear | Gears | Industrial districts, slain mechanical monsters | Mechanical modules, frames |
| Scrap | Work scrap | Everywhere, search ring, salvage | Basic items, repairs, armor |
| Chip | Electronics | Lumen Campus, Deepwright, rare finds | Spark modules, mechanisms |
| Drop | Ichor (beast blood) | Slain/captured monsters, black market | Blood modules, formulas |
| Fang | Trophies (fang, eye, chitin…) | Body parts broken in combat | Special and legendary blueprints |
| Coin | Money | Contracts, tavern, selling | Rent, shop, weapons, treatment |

## 6.2 Blueprints

Blueprints come from the skill webs, the shop, special missions and faction rewards. In the workshop the player selects a blueprint, sees the cost and crafts it. A workshop day allows **2 crafts**.

- **Tiers:** modules have tiers I–III; upgrading costs resources and a workshop day.
- **Salvage:** returns 50% of resources — the player is never punished for experimenting.
- Shop-bought modules and blueprints are a shortcut for money instead of resources.

## 6.3 How it works now (Phase 4 step 1, owner 2026-10-12)

| Rule | Value |
|---|---|
| Resources | Scrap, gears, electronics, ichor + trophies by id; shown on the district bar and in the workshop. Start stock: 8 scrap, 4 gears. |
| Loot | A won fight: ichor and scrap by the creature's rank (A 1+2 · P 2+3 · D 3+5 · S 5+8), ichor ×2 for a capture, the creature's own extra (`monsters[].loot`: Lamplighter gears + electronics, Rust Mantis gears, Clay Saint electronics), trophies of broken parts. A lost fight gives nothing. Rumors: a discovery gives scrap / gears / electronics, an empty night a little scrap (GDD 8.4). |
| Blueprints | `data/gear/blueprints.json`. 8 known at the start (simple gear modules incl. the scope and the net caster); the other 12 modules and all 4 mechanisms are taught by the **first find of a trophy** of a Grey Chapels creature (throat, finger bone, lantern glass, fang, sinew, wyrm tooth, chitin, tail spike — 2 items each), and then cost one such trophy. |
| Workshop day | The first craft or upgrade of a day starts a workshop day: 2 items; leaving the workshop ends the day. Salvage and fitting gear are free. |
| Tiers | Each module has its own tiers II and III (`modules.json → tiers`): card modules get stronger versions of their cards (`data/cards/tiers.json`, same art), bonus modules bigger bonuses. **An upgrade raises the module kind** — every copy, and copies crafted later. Cost: tier II = the base resources, tier III = twice that. Mechanisms have no tiers. |
| Salvage | A spare item (not in a cell or socket) → half its resource cost back, rounded down; trophies are not returned. |

Screen: `scenes/workshop/` (GDD 23.1). Code: `core/rules/workshop/workshop_rules.gd`, `loot_rules.gd`, `core/state/workshop_state.gd`.
