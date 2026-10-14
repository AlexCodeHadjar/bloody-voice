# 8. Investigation

> **Owner, 2026-10-14 — listening for rumors.** The old morning diamonds, the rumor post, «Расследовать (весь день)»
> and the Scriptorium's «Проверить слух» are gone. The hunter **listens to the street** in a zone of the district map;
> rumors surface there; he keeps the right ones in his notes; three right ones bring the contract's creature out, three
> wrong ones bring an unknown threat. Section 8.4 is the rule as built; 8.2 (tags) still holds.

## 8.1 Flow

1. Take a contract on the tavern board (GDD 7): it says in which **zone** the creature was last seen.
2. Walk the hunter into a zone and press **«Слушать улицу»** (the button shows while he stands still; it works in any
   zone, with a contract there or not). Blue rings spread from him like a locator and fade at the zone's border.
3. Every few seconds a **rumor icon** flares up somewhere in the zone (at most three at a time; an unread one fades).
4. A click opens the **rumor**: who tells it and what they heard and saw — a few **signs** of a creature.
5. The player compares the signs with the contract's known signs and decides: **«Взять в записи»** or **«Отбросить»**.
6. Three **right** rumors taken → the **creature's mark** appears in the zone: a click starts the fight (the day ends
   after it). Three **wrong** rumors taken (the count is hidden) → a **red mark of an unknown threat**: an optional fight
   with any creature of the district; it fades after a few days.
7. Listening is free; only the fight costs the day. Walking away pauses it; the button again stops it.

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
- High **Cunning** may whisper that a rumor is suspicious ('this sounds made up').
- The rumor shows a **confidence line**: 'matches 2 of 3 known signs' — never a guarantee.
- A right rumor taken adds its true signs to the contract, so each next decision is better informed.
- **Rival hunters** (Pale Hounds, Weavers) may take rumors too (later).

## 8.3 Outcomes

| Taken rumor | What happens |
|---|---|
| Right (about the creature of a contract taken in this zone) | +1 to that contract's trail (shown in the contracts list, «След 2/3»); its true signs are added to the contract's known signs. At the trail's goal the creature's mark appears in the zone. |
| Wrong (another creature, or lies) | +1 to the zone's hidden threat count. At its goal a red mark appears: an unknown threat. |
| Discarded | Nothing; it is gone. |

## 8.4 How it works now (owner 2026-10-14)

| Rule | Value (`balance.json → rumors`) |
|---|---|
| Listening | «Слушать улицу» while the hunter stands; a new rumor every `listen_every_min`–`listen_every_max` s at a random free street point of the zone, at most `max_heard` at once (+ the district state's `rumor_bonus`), an unread one fades after `heard_seconds` s. Blue rings from the hunter to the zone border. Walking pauses, the button stops. |
| Right or wrong | In a zone with a taken contract whose creature is not found yet a rumor is about it with chance `true_chance`; otherwise it is about another creature of the district (`wrong_creature_chance`) or lies. A creature rumor shows `true_tags_min`–`true_tags_max` of its signs (and its affixes' signs) and with `noise_chance` one lie; a rumor of lies shows `lie_tags_min`–`lie_tags_max` signs people of that zone talk about (`rumors.json → zones`). A right rumor whose creature is already found only teaches its signs. |
| The rumor | Picture of the zone, the witness line, the signs; for each contract taken in this zone «Совпадает N из M известных примет» and its trail; Cunning may whisper «Чутьё: слух сомнительный» on a wrong one. «Взять в записи» / «Отбросить». |
| Goals | `trail_needed` right rumors → the creature's mark (stays while the contract is open); `threat_needed` wrong ones in a zone → a red threat mark for `threat_days` days, a random creature of the district. |
| Fight | A click on a mark → the fight on the zone's background; the contract resolves as before (GDD 7); a threat gives loot and XP. |
| Time | Listening and taking rumors are free; the fight ends the day. |
| Gone | Morning diamonds, the rumor post (Bonfire Square is «soon» now), «Расследовать (весь день)», the Scriptorium's «Проверить слух», the rumor overheard in a tavern shift, discovery / false lead / empty night. |
| Not yet | Rival hunters taking rumors (with factions). |

Code: `core/generation/rumor_generator.gd` (a heard rumor, never saved), `core/rules/rumors/rumor_rules.gd` (hear, take,
trails, threats, marks, the morning tidy-up), `core/state/rumors_state.gd` (trails, hidden threat counts, marks; save v18),
screens `scenes/rumors/` (`listen_layer` — the button, rings, rumor icons and marks; `rumor_sheet`; `mark_sheet`).
