# 10. Capture and Research

## 10.1 Capture

- Capture contracts issue special **capture consumables** for the duration of the contract. They appear **only** in fights against that contract's target.
- Chance formula (start values):

```text
chance = card_base * (1 - hp / max_hp) * (1 + 0.04 * cunning) * (1 + 0.15 * broken_parts)
clamp(chance, 0.0, 0.95)
on failure: the monster becomes Enraged for 1 turn (+damage)
```

| What to do with a captured creature | Result |
|---|---|
| Hand over to the client | Full contract reward |
| Sell to a faction (Collegium, House Morrell) | Money + reputation, client is angry |
| Keep for experiments | Pure blood sample (stronger Monster node), Voice +1, moral weight |

## 10.2 Research

Research contracts reward knowledge. The player must play **Observe** on body parts and survive a number of turns. Rewards go to the **Bestiary**.

## 10.3 The Bestiary

- Each creature has a page: silhouette, tags, weaknesses, body parts, deck.
- Knowledge levels: Seen → Fought → Slain → Captured → Dissected (library).
- Knowledge works in combat: +1 intent preview, revealed weakness (+50% damage of a type), revealed ultimate card.
- In Ironman mode the Bestiary carries over to a new game.

## 10.4 The Bestiary now (Phase 6 step 4, owner 2026-10-12: knowledge helps)

| Rule | Value |
|---|---|
| Marks | Per creature: **seen** (a contract on it taken, or a fight begun), **fought**, **slain**, **captured**, **dissected** (a trophy studied in the Crypt Scriptorium — studying is allowed even with no contract on the creature until it is dissected). |
| Bonuses | In fights with that creature (`balance.json/bestiary`): slain — see its moves at the start; captured — +2 damage to body parts; dissected — +2 shot damage. Fought opens its page: HP, body parts with HP, moves. |
| Screen | «Бестиарий» from the district bar (`scenes/bestiary/`): the district's creatures with the five marks, an unseen one is a black silhouette; the page lists what each mark gives. New marks are listed in the fight result. |
| Scope | Grey Chapels creatures only (owner 2026-10-12). Weakness types, the ultimate card and Ironman carry-over come later. |
