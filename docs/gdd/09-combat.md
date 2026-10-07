# 9. Combat

## 9.1 Screen layout

```text
+--------------------------------------------------------------+
|  [intent]        [ ENEMY CARD + silhouette ]        [intent] |
|   left                body parts / phases               right |
|                                                              |
| HP  40/40                                                    |
| SAN 28/28                                                    |
| AP  3/3                                                      |
| VOICE stage 0          [ HERO CARD ]  [ WEAPON CARD: ammo ]  |
|                                                              |
| [draw pile]   [  hand of cards on the hunter's tablet  ]  [discard] |
+--------------------------------------------------------------+
```

- **Top centre:** the enemy card. Its planned actions are shown as cards **to the left and right** of it; hovering shows their direction (target).
- **Bottom centre:** the hero card. To its right: the **weapon card** with ammo.
- **Left edge:** HP, Sanity, AP and Voice as icons with numbers.
- **Draw pile** (cards not in hand or discard, always shuffled) and **discard pile** (played or discarded at end of turn).

## 9.2 Turn structure

1. Start of turn: restore AP, draw 5 cards (+Agility bonus). Enemy intents for its next turn are already visible.
2. Player plays cards by dragging them onto a target (enemy, enemy body part, or self).
3. End of turn: unplayed cards go to the discard pile (unless Retain).
4. Enemy turn: plays its revealed intents, then reveals the next ones.
5. When the draw pile is empty, the discard pile is shuffled into it.

## 9.3 Card types

| Type | Cost | Notes |
|---|---|---|
| Attack | AP | Damage, may target a body part |
| Support | AP | Block, buffs, draw, debuffs, Observe |
| Consumable | 0 AP | Single use, destroyed after play (bombs, tonics, antidotes, immunity) |
| Capture | AP or 0 | Contract-only; chance grows as enemy HP drops |
| Rage | 0–1 AP | Added by the Voice; strong but costs HP or Sanity |
| Curse / Fear | unplayable or costly | Added by monsters; clog the hand |

## 9.4 Monsters in combat

- Each monster has **its own deck** and plays visible intents.
- **Body parts** are separate targets with HP. Breaking a part removes a card from its deck and drops a **trophy** (e.g. break the jaw — no more Bite).
- **Phases:** at 50% HP the silhouette cracks and reveals the true form, the deck changes.
- **Environment** comes from the rumor's tags: fighting 'in fog' or 'near water' adds field modifiers. A player who read the rumor right prepares the right mechanisms.
