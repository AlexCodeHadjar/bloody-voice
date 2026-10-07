# 18. Development Roadmap

## 18.1 Principles that optimise the work

- **Vertical slice first.** By the end of Phase 4 the prologue + one week of Chapter I is fully playable with placeholder art. Everything after that is adding content to a working machine.
- **Data-driven from day one.** Cards, monsters, modules, districts, states, events are JSON. New content = new data, not new code.
- **Three parallel tracks:** Code, Content (data + writing) and Art Generation. Art runs one phase behind the code that needs it; placeholders are always allowed.
- **Tools before content.** A validator and a small content editor save more time than they cost.
- **Bots test balance.** An autoplay bot plays thousands of fights and weeks to find broken cards and impossible deadlines.
- **Every phase ends with a playable build, green tests and a short changelog.**

## 18.2 Phases

| Phase | Goal | Deliverables | Exit criteria | Est. |
|---|---|---|---|---|
| 0. Foundation | A clean skeleton that will not need to be rewritten | Folder structure, autoloads (EventBus, ContentDB, GameState, SaveService, Rng), content loader + validator, test runner, CLAUDE.md, coding standards | Empty game boots, loads data, validator fails on broken data, tests run in CI/headless | 1–2 w |
| 1. Combat core | Grey-box card combat | CombatSession (pure), cards as data, effects interpreter, AP, draw/discard, enemy deck + intents, body parts, combat screen | One full fight playable; bot can play 1000 fights headless | 3–4 w |
| 2. Gear = deck | Equipment builds the deck | Weapon tablet with grid + polyomino modules, armor sockets, mechanisms, deck assembly, ammo/reload | Changing modules changes the deck; tests for grid placement | 3 w |
| 3. Investigation | Contracts and rumors | Tavern board, contract tablet, tracker, map with figure, search ring, rumor tablet, tag matching, outcomes; ContractGenerator + RumorGenerator v1 | Contract → rumor → fight → reward loop works with generated content | 4 w |
| 4. Time, city, economy — VERTICAL SLICE | The day loop | Calendar, day actions, rent, shop, workshop crafting, library, tavern shift, Hunter's Fall; 3 districts | Prologue + 1 week playable start-to-end; first external playtest | 3–4 w |
| 5. Art generation pipeline (parallel from Phase 1) | Consistent look | Style bible, prompt files, city sketch, import tool (PNG → webp, naming check), placeholder → final swap | Map, 3 districts, UI props and 6 monsters in final style | ongoing |
| 6. Progression | Long-term goals | Levels, attributes, Mechanic + Monster skill webs, Voice stages, Bestiary, factions & reputation, Register rank | A full Chapter I week shows meaningful build choices | 4 w |
| 7. Living city | Districts change | District state system, transitions, overlays, EventScheduler, all 12 districts in data | Storm Season and Fog Breach work end-to-end, saved and loaded | 3 w |
| 8. Chapter I content | First complete chapter | Story contracts, dialogues, 8–10 monsters, 40–60 cards, all Chapter I art | Chapter I completable; bot finishes it; playtest | 6–8 w |
| 9. Chapters II–III | Full campaign | Transition Zone + Lower City layers, Ruins, finale, endings, remaining monsters | Game completable with all endings | 10–12 w |
| 10. Polish and release | Ship it | Balance pass (bots + humans), audio, VFX, tutorial hints, localisation RU/EN, performance pass, Steam build | No blockers, stable 60 FPS, all tests green | 6 w |

> **Note:** Estimates assume one developer working with AI assistance. The order matters more than the numbers: never start content production (Phase 8) before the vertical slice (Phase 4) is fun.

## 18.3 Generation track inside the roadmap

| Phase | Procedural generation | AI art generation |
|---|---|---|
| 0–1 | Rng service with named streams; seeded tests | Style bible; 3 test images to lock the style |
| 2 | — | Weapon tablet, module and resource icons |
| 3 | ContractGenerator v1, RumorGenerator v1, OutcomeResolver | City sketch → full city map; rumor diamond, search ring, tavern board, contract tablet |
| 4 | ShopGenerator | Shop table, hero figurine (4 views), 3 district tiles + scenes |
| 6 | LootGenerator, MonsterVariant | Monster silhouettes + cracked versions |
| 7 | EventScheduler | State variants for the 3 slice districts |
| 8–9 | Tuning tables by chapter | All remaining districts, variants, Lower City layers |
