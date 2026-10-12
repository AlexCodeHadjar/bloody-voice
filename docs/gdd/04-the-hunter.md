# 4. The Hunter

## 4.1 Attributes

| Attribute | In combat | Outside combat |
|---|---|---|
| **Will** | Max Sanity; resistance to Fear and Curse cards | Thresholds of the Voice (corruption); resisting story temptations |
| **Agility** | +1 card drawn at 4 and 8; dodge chance; bonuses for light modules | Speed of the search ring growth |
| **Cunning** | Preview depth of enemy intents; capture chance; trap power | Rumor analysis (flags noise tags), shop prices, contract reward bargaining |

## 4.2 Resources of the hero

| Resource | Start | Rule |
|---|---|---|
| HP | 40 (+5 per level) | 0 HP in combat = Hunter's Fall (clinic, losses, Scar). |
| Sanity | 20 + 4 × Will | Damaged by Fear. At 0 the hero panics: useless cards enter the hand for the rest of the fight. |
| Action Points (AP) | 3 per turn | Spent to play cards. Consumable cards cost 0 AP but are destroyed after use. |
| The Voice (corruption) | 0 | Grows with blood formulas and mutations. Stages at 10 / 20 / 30 (+3 per Will point). |
| Level / XP | Level 1 | XP from slaying, capturing and researching monsters. Level cap 15. |

## 4.3 Levelling

- Each level: **+1 skill point**. Levels 5, 10 and 15 give an extra point.
- Every second level: **+1 attribute point** (Will, Agility or Cunning).
- Skill points are spent in two **skill webs**: the Mechanic and the Monster.

## 4.4 Skill webs

Screen layout: GDD §23.2.

Each web is a **graph** (spider-web) growing outward from the centre. A node can be bought when it is connected to an owned node. Both webs have the same directions:

| Direction | Content |
|---|---|
| Equipment | Four sub-webs: **Helmet**, **Chestplate**, **Gauntlets & Pauldrons**, **Greaves**. Each piece has its own branches (e.g. Helmet: Perception / Focus / Masks). |
| Weapon | Frames and base weapon blueprints, ammo types, weapon handling passives. |
| Weapon modules | Blueprints for modules that go into weapon grid cells. |
| Mechanisms | Blueprints for mechanisms that go into free armor sockets; extra sockets. |

| Node type | Effect |
|---|---|
| Passive | Small permanent bonus (+HP, +capture chance, +ammo). |
| Blueprint | Unlocks a craftable item in the workshop. **Everything from the webs is a blueprint, not a free item.** |
| Socket | Adds a mechanism socket to an armor piece. |
| Keystone | Rule-changing node at the edge of a web (e.g. 'Reload draws a card'). |

### The Mechanic web

Engineering, precision and control. Safe and predictable. Rich in Support cards, traps, armor sockets and electric modules. Key blueprints come from the Lumen Collegium and the Order of the Iron Vigil.

### The Monster web — the Voice

- Nodes are **blood formulas** of specific creatures (e.g. 'Formula of the Vigil Hound'). A formula node can only be bought if the hero owns a **blood sample** of that creature — from a kill (normal sample) or a capture (pure sample, stronger node).
- Every formula adds **Voice**. Stages of the Voice:
  - Stage 1 — Whispers: Rage cards sometimes enter the deck (strong, but cost HP).
  - Stage 2 — Hunger: one card per turn may be played automatically.
  - Stage 3 — The Beast: unlocks Beast Form (huge power); after the fight there is a chance of losing control (story consequence).
- The Voice is reduced by Collegium sedatives, Morrell treatments and Rest days — at the cost of money and time.
- Monster nodes unlock **blood sockets** in the weapon and armor.

## 4.5 Health between fights (Phase 4 step 3, owner 2026-10-12)

| Rule | Value |
|---|---|
| Carry-over | HP and Sanity stay as the last fight left them (district bar: «HP x/y · Рассудок a/b», red below a third). Sanity 0 means the next fight starts in panic. |
| Rest | Ash Garret, a day: +⅓ of max HP and max Sanity. |
| Infirmary | The Ash Sisters (place 16, action `infirmary`): a day and 5 + 1 per missing HP + 1 per missing Sanity → full HP and Sanity. No credit. |
| Hunter's Fall | 0 HP in a fight: the sisters pick the hunter up — one more day passes (two in all), the fee of 30 is taken even into debt, HP and Sanity are restored, the fight's loot and trophies are lost. Scars come later (Phase 6). |
| Scriptorium | Crypt Scriptorium (place 12, action `library`), a day: **verify a rumor** (its tablet then shows what it leads to) or **study a trophy** (spent; every taken or pinned contract on its creature learns one more true sign). Bestiary, blueprints from books and Cunning checks come later. |

Numbers: `balance.json → health`. Code: `core/rules/health/health_rules.gd`, `core/rules/library/library_rules.gd`,
screens `scenes/places/` (infirmary, Scriptorium).

## 4.6 Levels and attributes now (Phase 6 step 1, owner 2026-10-12)

| Rule | Value |
|---|---|
| XP | A won fight by the creature's rank (A 20 · P 35 · D 60 · S 100), a capture ×1.5; a finished contract +15; a rumor discovery +5. |
| Levels | Level n → n+1 costs 50 + 25 × n; cap 15. Each level: +1 skill point (+1 more at 5, 10, 15), +5 max HP; every second level +1 attribute point. Skill points wait for the webs (step 2). |
| Start | Will 1, Agility 1, Cunning 1. Sanity = 20 + 4 × Will (was a flat 28: the start is 24 now). |
| Will | +4 Sanity per point (the Voice thresholds come with the Monster web, step 3). |
| Agility | +1 card in hand at 4 and 8; 3 % per point to slip a hit (a free dodge, logged; the start Agility 1 already gives 3 %). |
| Cunning | Capture chance (as before), +1 creature move always visible at 3 and 6, a 10 % per point chance to see a rumor's noise sign as «звучит выдумано» (fixed per rumor), 3 % shop discount per point (max 30 %). |
| Screen | «Охотник» on the district bar: level, XP bar, HP, Sanity, free points, attributes with «+». The fight result shows the XP and «Новый уровень!». |
| Points | One pool for both webs; resetting the Mechanic web costs money (owner) — built with the webs. |

Numbers: `balance.json → progress`. Code: `core/rules/progress/progress_rules.gd`, `core/state/progress_state.gd`,
screen `scenes/hero/hero_panel.gd`.

## 4.7 The Mechanic web now (Phase 6 step 2, owner 2026-10-12)

| Rule | Value |
|---|---|
| Shape | `data/skills/mechanic.json`: the start and 6 nodes per direction — Gear (up: max HP, a socket in each armor piece, keystone «Железная шкура»), Weapon (right: shot / part damage, a bullet, the Coil and Nozzle blueprints, keystone «Спокойные руки»), Modules (down: first-turn card, bleed, the Ichor / Capacitor / Galvanic blueprints, keystone «Умелец» = +1 workshop craft), Mechanisms (left: the 4 mechanism blueprints, first-turn AP, keystone «Запасные гнёзда» = +1 socket in every piece). 24 nodes, ~17 points by level 15. |
| Buying | 1 point of the shared pool; a node needs an owned linked node. Blueprint nodes are a second way to existing trophy blueprints — crafting still takes the trophy. |
| Reset | In the Scriptorium: 15 money per refunded point, no day, no credit; learned blueprints stay; mechanisms in vanished sockets go back to spare. |
| Screen | «Развитие охотника» (`scenes/skills/`, from «Охотник» → «Ветки навыков»): drag and wheel-zoom web, node pictures by type, owned lit, buyable in a pulsing gold ring, locked dark; the node card with «Изучить». The Monster tab came in step 3 (§4.8). |

## 4.8 The Monster web and the Voice now (Phase 6 step 3, owner 2026-10-12)

| Rule | Value |
|---|---|
| Shape | `data/skills/monster.json`: the start, a branch per Grey Chapels creature (Сточный Хор up, Фонарщик right, Сторожевой Пёс down, Роющий Змей left) — formula I (+2 Voice), formula II (+3), a keystone (+4, needs a **pure** sample) — and 4 blood nodes between neighbouring branches (+1 Voice, no sample). 16 nodes. |
| Samples | A kill gives 1 blood sample of the creature, a capture 1 pure sample (`LootRules`). A node costs 1 skill point and **uses up** its sample: a formula takes a normal one first, else a pure one; a keystone only a pure one. Samples sell in the shop for the creature's trophy price, pure ×2. |
| Stages | Voice 10 / 20 / 30, each +3 per Will (`balance.json/voice`). 1 Шёпот: «Ярость гончей» in every fight's deck. 2 Голод: at a turn's start an attack card in hand may play itself at the creature (30%, free). 3 Зверь: «Облик Зверя» in the deck; after a fight a 25% chance the Beast takes over — one more day passes. The node card warns when a purchase crosses a stage. |
| Lowering | Rest at the garret −1; the Ash Sisters' «Успокоить кровь» −5 for 20 money and a day (no credit). |
| Reset | The Monster web is never reset. |
| Shown | The Voice and its stage on the district bar (hidden while silent) and on the skill screen; the combat portrait darkens by stage; the fight result lists the sample and warns when the Beast took over. |
| Deferred | Blood sockets in weapon and armor; story consequences of losing control; Collegium sedatives and Morrell treatments (other districts — owner 2026-10-12: one district until he says so). |
