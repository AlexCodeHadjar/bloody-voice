# 8. Investigation

> **Owner, 2026-10-15 — the hunter's notebook.** Listening to the street (2026-10-14: the button, blue rings, rumor
> icons, the rumor sheet, the unknown threat) is gone too. Rumors are **overheard on the way** and **asked in the
> tavern**; they go into the **notebook**, a detective board where the player ties **red threads** from their signs to
> contracts. Section 8.4 is the rule as built; 8.2 (tags) still holds.

## 8.1 Flow

1. Take a contract on the tavern board (GDD 7): it says in which **zone** the creature was last seen.
2. Gather rumors: walking through a zone the hunter sometimes **overhears** one — a scrap of it shows over him
   («…детское пение…») and a leaflet flies into the **notebook** on the top bar (a count of new cards on it). In the
   tavern **«Расспросить»** gives 2–3, once a day. Nothing stays on the map.
3. Open the notebook: a board of dark wood — the taken contracts on the left (their signs, a slot for a new one, the
   trail), the rumor cards pinned on the right (the zone, who told it, the signs).
4. Hold a rumor's sign and pull a **red thread** to a contract. It **holds** when the rumor is about that contract's
   creature and the sign is true — the contract learns the sign if it is new. Otherwise it **snaps** and the rumor
   burns.
5. Three rumors on a contract's threads → the creature's **lair** appears in its zone on the map. Walk there, «В бой»;
   the day ends after the fight.
6. Gathering and tying are free; only the fight costs the day. Loose cards stay until thrown away.

## 8.2 Tag system

Every monster has 4–6 sign tags across categories:

| Category | Examples |
|---|---|
| Sound | grinding metal, children singing, church bell, sudden silence (birds stop) |
| Trace | three parallel furrows, acid burns, frost, slime, no traces at all |
| Victims | children vanish, bodies drained dry, eyes missing, people come back 'different' |
| Time | only in fog, only at full moon, during rain, in daylight |
| Place | underground, rooftops, near water, inside churches |
| Shape | too tall, many arms, hunched, 'a man, but wrong' |

- A rumor carries 1–3 tags; some may be **noise** (lies or confusion).
- High **Cunning** may stamp a wrong rumor «Чутьё: слух сомнительный».
- The board shows the rumor's signs beside the contract's known signs; the player compares them — never a guarantee.
- A thread that holds adds its sign to the contract, so each next decision is better informed.
- **Rival hunters** (Pale Hounds, Weavers) may take rumors too (later).

## 8.3 Outcomes

| Thread | What happens |
|---|---|
| Holds (the rumor is about this contract's creature, the sign is true) | The card is on the contract's thread (one card counts once; more of its signs can be tied); a new sign is added to the contract. At three cards the lair appears. |
| Snaps (another creature, lies, or a lie among true signs) | The rumor card burns. |
| Thrown away (✕) | The card is gone; a card on a thread can't be thrown away. |

## 8.4 How it works now (owner 2026-10-15)

| Rule | Value (`balance.json → rumors`) |
|---|---|
| Overhearing | While the hunter walks, a roll every `overhear_steps` footsteps with `overhear_chance`, at most `overhear_per_day` a day (+ the district state's `rumor_bonus`); the rumor is about the zone he walks. A scrap of it over him (its first sign, which may be a lie), a leaflet flies into the notebook, a count of new cards on its icon. |
| Asking | The tavern card: «Расспросить» — `ask_min`–`ask_max` rumors about any zones, once a day. |
| Right or wrong | A rumor is about a taken contract whose lair is not found yet (in that zone; asked ones — any) with `true_chance`; otherwise about another creature of the district (`wrong_creature_chance`) or lies the zone talks about (`rumors.json → zones`). A creature rumor shows `true_tags_min`–`true_tags_max` of its signs (and its affixes' signs), with `noise_chance` one lie; lies show `lie_tags_min`–`lie_tags_max`. |
| Notebook | Up to `notebook_max` cards; when full, nothing more is overheard or asked. Cards stay until thrown away; cards on the threads of a closed contract go with its lair. Cunning may stamp a wrong one «Чутьё: слух сомнительный». |
| Threads | Holds / snaps as in 8.3. `trail_needed` cards on a contract's threads → the lair on a free street point of its zone. |
| Lair | A dark disc with a red glow and claw marks (drawn in code until its art comes). Click → the hunter walks there → «В бой» / «Не сейчас». The contract resolves as before (GDD 7). |
| Time | Overhearing, asking and tying are free; the fight ends the day. |
| Gone | Morning diamonds, the rumor post, «Расследовать», the Scriptorium's «Проверить слух», the tavern-shift rumor (2026-10-14); listening to the street, rumor icons and rings, the rumor sheet, the unknown threat (2026-10-15). |
| Not yet | Rival hunters taking rumors (with factions). |

Code: `core/generation/rumor_generator.gd` (a rumor card), `core/rules/rumors/rumor_rules.gd` (overhear, ask, link,
discard, the lair, the morning tidy-up), `core/state/rumors_state.gd` (cards, lairs, asked places; save v19), screens
`scenes/rumors/` (`notebook_board` + `notebook_cards` + `thread_view` — the board; `overhearing` — the scrap and the
flying leaflet; `mark_layer` — lairs on the map; `mark_sheet`), the notebook icon on `scenes/district_map/district_bar.gd`.
