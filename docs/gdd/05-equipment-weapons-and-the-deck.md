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
Deck = Base cards (6)
     + cards from the weapon (frame + installed modules)
     + cards from armor mechanisms
     + consumables chosen for this mission (single use)
     + contract-only capture consumables (only on that capture contract)
     + Curse/Rage cards added by the Voice or by monsters
```

The number of cells and sockets naturally limits deck size. There are no random 'pick 1 of 3 cards' rewards: **the player builds the deck by crafting and installing**.

## 5.4 The weapon in combat

- The weapon card sits to the right of the hero and shows **ammo**. Weapon attack cards spend ammo; 'Reload' costs 1 AP (or a card).
- Some frames build **heat** instead of ammo (electric weapons): overheating skips the next weapon card.
