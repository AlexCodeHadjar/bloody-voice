# 2. Story Structure

## 2.1 Chapters

| Chapter | Length | Area unlocked | Main thread |
|---|---|---|---|
| Prologue — First Blood | 3 days | Grey Chapels (slums): tavern, workshop | Tutorial hunt. The hero takes his first injection of beast blood and hears the Voice for the first time. |
| I — The Lantern & Hook | 4 weeks | Upper City (all 12 districts) | Disappearances across the city lead to the Church of the Pale Vault and the Masked Moon. Factions introduce themselves. |
| II — Beneath the Platform | 4 weeks | Transition Zone, Lower City levels 6–5 | Deepwright Company, the Grey Communion, an uprising below. A section of the platform collapses. |
| III — Where Voices Gather | 4 weeks | Levels 4–1, Ruins of the Old Capital | The fissure into the Underdream. The source of the Voice. Final hunt. |
| Finale | 1 battle | The Underdream Fissure | Ending depends on faction standing and the Voice level. |

## 2.2 Story gates and deadlines

- Each chapter has 3–4 **story contracts** with deadlines. Missing a deadline does not end the game: it branches the story (someone dies, a faction turns hostile, a district changes state).
- Between story contracts the player is free to take side contracts, craft, train and build reputation.
- A chapter ends when its final story contract is resolved or its last day passes.

## 2.3 Endings (draft)

| Ending | Condition |
|---|---|
| The Hunter | Voice below stage 2 at the finale. The hero seals the fissure and stays human. |
| The Hybrid | Voice at stage 2. The hero controls the beast and becomes a new kind of guardian — feared by the city. |
| The Beast | Voice at stage 3. The hero becomes the thing he hunted; epilogue from the next hunter's view. |
| Faction variants | The faction with the highest standing decides what happens to the Lower City and the Mistveil. |

## 2.4 The Grey Chapels story now (Phase 8 step 2, owner 2026-10-12)

| Rule | Value |
|---|---|
| Plot | «The mystery of the Grey Communion» (Claude's draft, the owner edits the texts): a grey candle with the Communion's seal in the Gutter Choir's drain → the Lamplighter, brought alive to the Ash Sisters, burns chapel incense and carries a list of the unclaimed dead → the Vigil Hound guards the crypt; its key opens the deacon's ledgers: the Communion feeds the creatures with the dead, and «it answers from below» → the Burrow Wyrm digs up through the crypt. At the end the hunter gives the ledgers to the Iron Vigil (Vigil +30, Communion −30) or burns them for the Communion (the reverse). |
| Steps | A prologue and 3 story contracts (`data/story/grey.json`; letters in `contracts/petitions.json`, type `story`): Gutter Choir (slay, 40), Lamplighter (capture, 70), Vigil Hound (slay, 80), Burrow Wyrm (slay, 140); end +80 XP. |
| Contracts | Taken at once when the step starts; **no deadline**, **no contract slot**, not on the weekly board, can't be given up; a fight with their creature counts for them before side contracts (exams first). They count for the Register rank and their petitioner's faction like any contract. |
| Letters | Told **only by letters and notes** (owner): the step's letter, its note once it is done, the end letter — on the district screen after the morning news, one after another (`LetterPanel`, portraits `NPC__portrait__*`). The last note asks for the choice and stays until it is made; closing it puts the choice off until the next morning or map visit. Old saves get the prologue on load. |
| Later | Story events in the calendar, branches from the choice, other districts' chapters. |

