# 5. Equipment, Weapons and the Deck

## 5.1 Armor

| Piece | Role | Example branches |
|---|---|---|
| Helmet | Perception, mind protection | Intent preview, Fear resistance, masks that change rumor reading |
| Chestplate | Survival | Armor, HP, Bleed and Acid resistance |
| Gauntlets & Pauldrons | Handling and strikes | Melee cards, reload speed, capture tools |
| Greaves | Mobility | Dodge, search ring speed, escape from fights |

Each piece has **mechanism sockets** (1 at start, up to 3 through the webs). **Mechanisms** add tags and cards: e.g. 'Lantern of Revealing' (+1 intent preview, card 'Flash'), 'Smoke Bellows' (card 'Smoke Screen'), 'Tag Reader' (rumor analysis bonus).

## 5.2 The weapon tablet

The weapon is shown as a **card**. Clicking it opens the **weapon tablet**: a side view of the weapon split into five sections. Each section contains connected square **cells** of different counts and directions.

| Section | Gameplay role |
|---|---|
| Sight (scope) | Crits, aimed shots at body parts, intent preview |
| Magazine | Ammo capacity, reload cards, ammo types |
| Stock | Defense, recoil, melee bash |
| Frame | Total number of cells and their types; the 'body' of the weapon |
| Barrel | Damage type (shot, slug, harpoon, flame), range |

- **Cell types:** Gear (mechanical), Spark (electric), Blood (opened by the Monster web).
- **Modules** are shaped like polyominoes (1–4 cells) and can be rotated.
- **Links:** modules touching each other can form combos (e.g. Coil next to Harpoon turns 'Shot' into 'Shock Harpoon').
- Hovering a weapon in the shop opens its tablet so the player can compare sections and stats before buying.

## 5.3 How the deck is built

```text
Deck = The hunter's own cards (10: 4 Strike, 4 Guard, Read the Beast, Sidestep)
     + the weapon's cards (Hunting Rifle: 2 Shot, Reload) + cards of installed modules
     + cards from armor mechanisms
     + consumables chosen for this mission (single use)
     + contract-only capture consumables (only on that capture contract)
     + Curse/Rage cards added by the Voice or by monsters
```

The number of cells and sockets naturally limits deck size. There are no random 'pick 1 of 3 cards' rewards: **the player builds the deck by crafting and installing**.

## 5.4 The weapon in combat

- The weapon card sits to the right of the hero and shows **ammo**. Weapon attack cards spend ammo; 'Reload' costs 1 AP (or a card).
- Some frames build **heat** instead of ammo (electric weapons): overheating skips the next weapon card.

## 5.5 Decisions and implementation (Phase 2)

Owner's decisions (2026-10-07):

- Modules **can be rotated** when installed (quarter turns).
- The hunter **starts with one weapon and one module**: the Hunting Rifle with a Brass Scope in the sight.
- Gear can be changed **anywhere outside a fight, for free** (no day spent).
- Armor sockets and mechanisms are part of Phase 2.
- The starter rifle layout stays "one module per section" (owner, 2026-10-07): **links start with the next
  weapon** — the rifle has single spark cells, so the Coil + Harpoon link needs a later weapon.
- Module cards are **real upgrades** over the hunter's basic cards (owner): gear is power progression, and the
  creatures of later chapters must grow to match it.
- **Duplicate modules are allowed and their effects stack**; the number of cells and the economy limit them.
- Swapping gear is free anywhere outside a fight, also in the middle of a contract.

Balance with full gear (bot, every section and socket filled — `tests/bot/full_gear.json`): every creature of the
current roster is won 99–100% of the time. Expected: the current 8 creatures are Chapter I opening targets. Later
chapters need stronger creatures or affixes (GDD §17, MonsterVariant).

Starting Hunting Rifle (25 cells; **G** = gear, **S** = spark):

| Section | Cells |
|---|---|
| Stock | 3×2 G |
| Frame | 3×2 G + 1 S at the top right |
| Magazine | 2×2 G |
| Sight | G G S |
| Barrel | G G G G S |

Every gear module fits somewhere in the starting rifle (checked by a test). Spark and blood cells are scarce on
purpose: they come with better weapons and the skill webs. Each armor piece has 1 socket at the start.

Rules: a module fits when all its cells lie inside its own section, on cells of its type, and overlap nothing.
Two modules **touch** when they share a section and an edge; links (e.g. Coil Accelerator + Harpoon Launcher)
swap cards in the deck. Passive bonuses (`core/content/gear_mods.gd`): `max_ammo`, `max_hp`, `shot_damage`,
`part_damage` (shots at a body part), `shot_block`, `shot_bleed`, `bleed_bonus`, `reload_draw`, `first_turn_draw`,
`first_turn_ap`, `foresight_start`, `rage_hp_discount`.

Data: `data/gear/weapons.json`, `modules.json`, `shapes.json`, `armor.json`, `mechanisms.json`; start gear in
`data/balance.json` → `gear`.

## 5.6 Mechanisms with a trade-off (Phase 8 step 4, owner 2026-10-12)

| Mechanism | Gives | Costs | Blueprint (trophy) |
|---|---|---|---|
| Heavy Plating | +14 max HP | first turn: 1 card less | tail spike (Burrow Wyrm) |
| Galvanic Harness | first turn: +1 AP, +1 card | a Dread curse in the deck | sinew (Vigil Hound) |
| Fog Lens | see 2 moves ahead at the start | 1 bullet less (never the last) | throat (Gutter Choir) |
| Ichor Injector | shots +3, body parts +1 | −6 max HP | fang (Vigil Hound) |
| Blood Pump | Rage cards cost 2 less HP, a Hound's Rage in the deck | −4 max HP | wyrm tooth (Burrow Wyrm) |

Data: `data/gear/mechanisms.json` (negative mods are the costs), blueprints in `blueprints.json`. Icons — `art/ui/icons/MECHANISM__*` (received 2026-10-14).


## 5.7 Screen sketch — the workbench (owner 2026-10-14)

`docs/assets/ui/equipment_workbench.png` — the next look of the Equipment screen (not built yet). The rifle lies large
on a workbench in the middle with its cells drawn on its parts (stock, frame, magazine, scope, barrel; leader lines);
left — a mannequin with the four armor sockets and their mechanism dots; right — a drawer with spare modules,
mechanisms and armor plates in tabs (a taken module follows the cursor, a green frame shows where it will go);
bottom — the battle deck as a fan of cards with counts, the hovered module's cards lit.
