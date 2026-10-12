# 11. Economy

| Money in | Money out |
|---|---|
| Contract rewards | Weekly rent for the workshop-home |
| Tavern shifts | Shop: consumables, modules, blueprints, weapons |
| Selling trophies, captured creatures | Treatment of HP / Voice at House Morrell |
| Faction bonuses | Bribes, passes into quarantined districts, Lower City permits |

## 11.1 The shop

- A permanent location, like the tavern. Shown as a **wooden table with cards** lying on it.
- Resources are sold as cards with the resource icon in the centre.
- Refreshes every Monday. Stock depends on the district state and on Rowan Exchange reputation.
- Weapons for sale: hovering opens the weapon tablet (sections, cells, stats).
- Consumables for missions: damage, healing, immunity to effects, utility.

## 11.2 Black market

In Scarlet Lantern Row: illegal modules, ichor, forbidden formulas. Buying lowers standing with the Order of the Iron Vigil and the Church of the Pale Vault.

## 11.3 How it works now (Phase 4 step 2, owner 2026-10-12)

| Rule | Value |
|---|---|
| Shop | «Тряпичник» (Rag-and-Bone Shop, Grey Chapels place 5, action `shop`), the dealer's table over the district map. New table every Monday: 3 ready modules, 2 blueprints the hunter does not know (a trophy-locked one still needs its trophy to craft), 3 consumables, 3 resource lots. |
| Prices | From resource values (scrap 3, gears 5, electronics 9, ichor 6): module = its blueprint's resources ×1.5, blueprint ×2, rounded to 5; lots = amount × price; consumables by table (tonic 15, fire flask 12, bandage 8, signal flare 8). No credit: buying needs the money in hand. |
| Selling | Trophies by the rank of the creature that drops them (A 8 · P 12 · D 20 · S 30), resources at half their price (at least 1). Items are not sold (salvage them in the workshop). |
| Bag | Up to 3 consumables; they go into every fight's deck and a played one is used up. |
| Tavern shift | A day action on the Lantern & Hook card: 15–25 money, a line of gossip, and next morning a rumor overheard at the bar (50 %: a true one about an open contract's creature). |
| Rent debt | Rent may push money below 0. 2 unpaid rents in a row shut the workshop for that day (crafting, upgrades and salvage refused); the count clears when money is back at 0 or more. Money shows red with the count. |

Numbers: `balance.json → shop`, `tavern`, `economy.debt_strikes`. Code: `core/generation/shop_generator.gd`,
`core/rules/shop/shop_rules.gd`, `core/rules/tavern/shift_rules.gd`, `DayRules` (debt), screens `scenes/shop/`, `scenes/tavern/`.
