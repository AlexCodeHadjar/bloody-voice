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
