# 12. Factions and Reputation

Reputation range −100…+100 with tiers **Hostile / Wary / Neutral / Trusted / Sworn**. It rises through faction contracts and fighting monsters on their territory. Trusted and Sworn unlock exclusive modules and **exclusive skill-web branches**.

| Faction | Home district | Unlocks | Conflicts with |
|---|---|---|---|
| Crown Magistracy | Crown Ward | High-pay secret contracts, rent relief | Scarlet Supper, Grey Communion |
| Order of the Iron Vigil | Vigil Spire Ward | Monster dossiers (contract tags revealed), knight armor | Scarlet Supper |
| Lumen Collegium | Lumen Campus | Mechanic+ branches, Register rank, sedatives | Grey Communion |
| Church of the Pale Vault | Silverhill | Healing, holy consumables, moon modules | Grey Communion; later the hero |
| Rowan Exchange (Harrow / Brannoc / Varga) | Rowan Market + gate posts | Shop discounts; Hawk = scopes, Bear = armor, Wolf = hunting gear | — |
| Hunter crews (Pale Hounds / Weavers) | Nordhal Quarter | Blood formulas (Monster web) | Each other — choose one |
| Scarlet Supper | Scarlet Lantern Row | Black market, forbidden modules | Iron Vigil, Pale Vault |
| House Morrell | Morrell Ward | Voice treatment, tonics | — |
| Deepwright Company | Deepwright Lifts | Lower City permits, resources | Grey Communion |
| Grey Communion | Grey Chapels / Lower City | Ichor, fog formulas, way into the depths | Almost everyone above |
| The Dusk Anointed | Hidden | Legendary 'Elder Mother' modules | — |

## 12.1 The Lumen Register (public rank)

- The Lumen Collegium publishes the **Register** of extraordinary beings: ranks **A** (Anomalous), **P** (Panic), **D** (Desolation), **S** (Sovereign).
- The hero has a public rank. It rises through deeds — defeating a creature of a higher rank.
- Rank unlocks higher contracts on the board and changes how factions treat the hero.
- The Register is published at the end of every chapter (an event with a recap).
- Places also have danger ranks; a district or area can be classified A/P/D/S (see section 13).

## 12.2 Factions and the Register now (Phase 6 step 4, owner 2026-10-12: one district for now)

| Rule | Value |
|---|---|
| Factions | Two local ones (`data/factions/factions.json`): **the Grey Communion** (the chapels and the Ash Sisters) and **the Iron Vigil** (the order's night watch); rivals of each other. |
| Reputation | −100…100; tiers from `balance.json/factions.tier_min`: Hostile ≤ −50, Wary −49…−10, Neutral −9…24, Trusted 25…59, Sworn ≥ 60. A finished contract: its petitioner's faction +8 (`petitions.json → faction`), the rival −3. Every won fight: a kill Vigil +1; a capture Communion +2, Vigil −1. |
| Effects | Communion — the infirmary's prices (treatment and calming the blood): Hostile ×1.5, Wary ×1.25, Trusted ×0.75, Sworn ×0.5. Vigil — new leaflets: Hostile reward ×0.8, Wary ×0.9, Trusted +1 known sign, Sworn +1 sign and reward ×1.2. |
| Register rank | The hunter starts at **A**. The board offers creatures up to one rank above the hunter's (A → A and P; P → also D). Contract rewards +10 % per rank above A. |
| Exam | After 3 / 4 / 5 finished contracts at a rank the Register pins an **exam leaflet** (petition `register_exam`): slay a creature of the next rank of the district, as strong as an overdue one, within 6 days; it takes no contract slot. Pass: the next rank, 60 / 100 / 160 money, 40 XP. Missed deadline: it goes; a new one next Monday. The Grey Chapels have no S creature, so the slice stops at D. |
| Shown | «Охотник»: rank, contracts left to the exam, reputation rows with tier effects in the tooltip; the board shows the rank; the fight result lists reputation changes and a passed exam. |
| Later | Faction-exclusive modules, skill branches and special contracts; the Register's chapter recap; factions of other districts. |
