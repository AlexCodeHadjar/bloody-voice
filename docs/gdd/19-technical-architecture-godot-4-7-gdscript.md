# 19. Technical Architecture (Godot 4.7, GDScript)

## 19.1 Principles

| Principle | How it is applied |
|---|---|
| Layered architecture | Data → Rules → State → Services → Presentation. A layer only depends on layers to its left. |
| Single responsibility | One mechanic = one rules file (`class_name`, static functions) + one test file. One screen = one scene + one script. |
| UI never owns logic | Scenes read state and send **commands** through the GameState facade. They never change RunState directly. |
| Pure, deterministic rules | Rules are static functions of (state, data, rng). No nodes, no globals inside rules. Easy to test and to run in bots. |
| Data-driven content | All content in `data/*.json`, loaded once into typed objects by ContentDB. Validator rejects bad data at start-up. |
| Events instead of coupling | Systems talk through `EventBus` signals (`day_changed`, `district_state_changed`, `card_played`). |
| Composition over inheritance | Monsters, cards and modules are data + small effect ops, not class hierarchies. |
| Open/closed effects | Card and module effects are data ops (`{"op": "damage", "amount": 6}`) interpreted by EffectApplier. New effect = one new op handler. |
| Static typing everywhere | Typed vars, typed arrays, return types. Write `var x: Type =` when the source is a Variant/Dictionary. |
| No magic numbers | All tuning values in `data/balance.json`. |
| Versioned saves | `SAVE_VERSION` + migration functions; saves are plain dictionaries of RunState. |
| KISS / YAGNI | No framework code 'for later'. Generalise on the second real use, not the first. |

## 19.2 Project structure

```text
bloody_voice/
  project.godot
  CLAUDE.md                     # map of the project for AI assistants (short!)
  autoload/                     # thin singletons only — no game rules here
    event_bus.gd                # all global signals
    content_db.gd               # loads + validates data/, exposes typed content
    game_state.gd               # facade: commands from UI -> rules -> state
    save_service.gd             # save/load + migrations
    rng_service.gd              # master seed, named streams
    settings_service.gd, audio_service.gd
  core/
    content/                    # data classes + loader + validator
      defs/  card_def.gd, module_def.gd, monster_def.gd, district_def.gd ...
      content_loader.gd, content_validator.gd
    state/                      # pure serialisable data
      run_state.gd, hero_state.gd, city_state.gd, contract_state.gd, combat_state.gd
    rules/                      # pure static logic, grouped by domain
      combat/        combat_rules.gd, deck_rules.gd, intent_rules.gd, effect_applier.gd, capture_rules.gd
      gear/          weapon_grid_rules.gd, deck_builder.gd, crafting_rules.gd
      investigation/ ring_rules.gd, tag_match_rules.gd, outcome_rules.gd
      time/          calendar_rules.gd, day_action_rules.gd
      economy/       economy_rules.gd, shop_rules.gd
      progression/   level_rules.gd, skill_web_rules.gd, voice_rules.gd, faction_rules.gd
      city/          district_state_rules.gd, event_rules.gd
    generation/                 # seeded generators
      contract_generator.gd, rumor_generator.gd, shop_generator.gd,
      event_scheduler.gd, loot_generator.gd, monster_variant.gd
    commands/                   # player intents as objects (undo/log/replay-friendly)
  data/                         # JSON content (one folder per type)
    balance.json
    cards/ modules/ weapons/ armor/ mechanisms/ monsters/ contracts/ rumors/
    tags.json  city/districts.json  city/district_states.json  events/ factions/
    skill_webs/mechanic.json  skill_webs/monster.json  story/chapter_1.json ...
  scenes/                       # presentation only
    hub/ tavern/ shop/ workshop/ library/ city_map/ investigation/ combat/
    tablets/ (contract, rumor, weapon)   common/ (card_view, tooltip, transitions)
  ui/theme/                     # palette, fonts, theme resources
  art/  audio/                  # imported game assets (webp/ogg) only
  docs/                         # GDD, prompts, asset sources (docs/.gdignore)
  tools/                        # python generators, importers, editors
  tests/
    run_tests.gd  test_*.gd     # one suite per rules file
    bot/autoplay.gd             # balance bot
```

## 19.3 Dependency direction

```text
Presentation (scenes/)  ──commands──>  GameState (facade)  ──calls──>  Rules / Generators
       ^                                        │                              │
       │  signals                               v                              v
   EventBus  <─────────────── emits ─────  RunState (data)  <──── reads ──  ContentDB (data)
```

Rules and generators never import scenes. Scenes never write to RunState. Only GameState mutates state, always by calling rules, then emits signals.

## 19.4 Code samples

### EventBus

```text
# autoload/event_bus.gd
extends Node

signal day_changed(day: int)
signal contract_accepted(contract_id: StringName)
signal rumor_spawned(rumor_id: StringName)
signal district_state_changed(target: StringName, old_state: StringName, new_state: StringName)
signal card_played(card_id: StringName, target: StringName)
signal combat_finished(result: Dictionary)
```

### A rules file (pure, static, typed)

```text
# core/rules/combat/capture_rules.gd
class_name CaptureRules
extends RefCounted

## Chance to capture a creature. Pure function: no globals, no nodes.
static func chance(card_base: float, hp: int, max_hp: int, cunning: int,
        broken_parts: int, balance: BalanceDef) -> float:
    var missing: float = 1.0 - float(hp) / float(max_hp)
    var bonus: float = (1.0 + balance.capture_per_cunning * cunning) \
            * (1.0 + balance.capture_per_broken_part * broken_parts)
    return clampf(card_base * missing * bonus, 0.0, balance.capture_max_chance)

static func roll(rng: RandomNumberGenerator, chance_value: float) -> bool:
    return rng.randf() < chance_value
```

### Effects as data

```text
// data/cards/shock_harpoon.json
{ "id": "shock_harpoon", "type": "attack", "cost": 2, "ammo": 1,
  "target": "enemy_part",
  "effects": [ { "op": "damage", "amount": 7, "kind": "pierce" },
               { "op": "apply_status", "status": "shocked", "turns": 1 } ] }
```

```text
# core/rules/combat/effect_applier.gd
class_name EffectApplier
extends RefCounted

const OPS: Array[StringName] = [&"damage", &"block", &"apply_status", &"draw"]  # validator uses this list

static func apply(state: CombatState, effect: Dictionary, ctx: EffectContext) -> void:
    var op: StringName = effect.get("op", &"")
    match op:
        &"damage": _op_damage(state, effect, ctx)
        &"block": _op_block(state, effect, ctx)
        &"apply_status": _op_apply_status(state, effect, ctx)
        &"draw": _op_draw(state, effect, ctx)
        _: push_error("Unknown effect op: %s" % op)  # never happens: validator checks OPS at start-up
```

### GameState facade (the only writer of state)

```text
# autoload/game_state.gd (fragment)
func investigate(rumor_id: StringName) -> void:
    var result: OutcomeResult = OutcomeRules.resolve(run, rumor_id, ContentDB.data)
    run = DayActionRules.spend_day(run, &"investigate")
    EventBus.day_changed.emit(run.calendar.day)
    if result.starts_combat:
        _open_combat(result.encounter)
```

### Seeded RNG streams

```text
# autoload/rng_service.gd
extends Node

var master_seed: int

func stream(name: StringName, day: int = 0) -> RandomNumberGenerator:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([master_seed, name, day])
    return rng
```

## 19.5 Coding standards

- GDScript style guide: tabs, `snake_case` for files/functions/vars, `PascalCase` for classes, `UPPER_CASE` for constants, `&"ids"` (StringName) for content ids.
- File size budget: **≤ 400 lines** per script, functions **≤ 40 lines**. Split before it grows (lesson from SunLess: 1200-line screens are hard to change).
- Every public function has a type signature and a one-line `##` doc comment.
- No logic in `_process`; screens refresh on signals and a queued refresh (`_queue_refresh`).
- Pool card views and diamond icons; cache derived data in ContentDB (`memo`).
- Every new mechanic: rules file + test suite + validator rules + tutorial hint entry.
- Content ids are stable: never rename an id that is in a save; add a migration instead.
- Commit after every phase step; tests must be green before a commit.

## 19.6 Testing and tooling

| Tool | Purpose |
|---|---|
| tests/run_tests.gd | Headless test runner, one suite per rules file; also a 'compile all scripts' test |
| content_validator.gd | Checks ids, references, effect ops, tags, district codes; the game refuses to start on errors |
| tests/bot/autoplay.gd | Plays fights and whole weeks with simple heuristics; reports win rate, deadlines missed, money curve |
| tools/gen_city_sketch.py | Regenerates the city sketch, cross-section and ASCII grid from one layout |
| tools/import_art.py | Imports generated art: checks naming (CODE__state), resizes, converts to webp |
| Auto-screenshots | `--shots=<dir>` runs scripted scenes and saves PNGs for visual review |

```text
G="/d/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import
"$G" --headless --path . -s res://tests/run_tests.gd
"$G" --headless --path . -s res://tests/bot/autoplay.gd -- --fights=1000
```
