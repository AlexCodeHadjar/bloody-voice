// Part 4 — procedural generation, roadmap, architecture, appendices
const { H1, H2, H3, P, Bul, Num, Note, Code, Tbl, KV } = require("./lib");

const generation = () => [
  H1("17. Procedural Generation"),
  P("Generation adds variety **inside** the authored story. Every generator is a pure function of `(seed, run_state, data)` so results are reproducible: the same save + seed gives the same board, rumors and shop. This makes bugs reproducible and balance testable by bots."),
  H2("17.1 RNG streams"),
  P("One master seed per playthrough. Each system gets its **own stream** derived from it, so adding a random call in one system never changes results in another."),
  Code(`master_seed -> stream("contracts") -> stream("rumors") -> stream("shop")
            -> stream("events")    -> stream("combat") -> stream("loot")
stream(name) = RandomNumberGenerator with seed = hash(master_seed, name, day)`),
  H2("17.2 Generators"),
  Tbl(["Generator", "Input", "Output", "Key rules"], [
    ["ContractGenerator", "week, chapter, district states, hero rank, reputation", "3–6 side contracts on the board each Monday", "Monster from district pool (weighted by state); reward scales with rank; deadline 4–10 days; never more than 2 of the same type"],
    ["RumorGenerator", "district, active contracts, day, Cunning", "Diamonds in the search ring", "Each active contract seeds 1 TRUE rumor per 2–3 days; others are wrong-monster / discovery / false / empty; 0–1 noise tags per rumor; weights from district state"],
    ["OutcomeResolver", "rumor, contract", "What happens on Investigate", "Determined when the rumor is generated (stored), so reloading does not reroll"],
    ["ShopGenerator", "week, Exchange reputation, district state", "Cards on the shop table", "Fixed slots: 2 weapons, 4 modules, 4 consumables, 3 resource lots; rarity by chapter"],
    ["EventScheduler", "chapter, day, flags", "Random world events", "Weighted table with cooldowns; at most 1 random event active; story events always win"],
    ["MonsterVariant", "base monster, chapter", "Affixes (e.g. 'Fog-touched', 'Starving')", "0–2 affixes; each adds 1 card to the monster deck and 1 tag"],
    ["LootGenerator", "monster, broken parts, outcome", "Resources, trophies, blood sample", "Trophy only from broken parts; sample quality by kill/capture"],
  ], [1.2, 1.5, 1.4, 2.6]),
  H2("17.3 Rumor generation example"),
  Code(`func generate_rumor(rng, district, contracts, data) -> Rumor:
    var kind := weighted_pick(rng, district.rumor_kind_weights)   # target / wrong / discovery / false / empty
    var source := contracts.pick_for(district) if kind == TARGET else data.monster_pool(district).pick(rng)
    var tags := source.tags.sample(rng, 1 + rng.randi() % 2)        # 1-2 true tags
    if rng.randf() < data.balance.noise_chance:                      # maybe 1 noise tag
        tags.append(data.tags.random_not_in(source.tags, rng))
    return Rumor.new(kind, source.id, tags, district.random_point(rng))`, 15),
];

const roadmap = () => [
  H1("18. Development Roadmap"),
  H2("18.1 Principles that optimise the work"),
  Bul([
    "**Vertical slice first.** By the end of Phase 4 the prologue + one week of Chapter I is fully playable with placeholder art. Everything after that is adding content to a working machine.",
    "**Data-driven from day one.** Cards, monsters, modules, districts, states, events are JSON. New content = new data, not new code.",
    "**Three parallel tracks:** Code, Content (data + writing) and Art Generation. Art runs one phase behind the code that needs it; placeholders are always allowed.",
    "**Tools before content.** A validator and a small content editor save more time than they cost.",
    "**Bots test balance.** An autoplay bot plays thousands of fights and weeks to find broken cards and impossible deadlines.",
    "**Every phase ends with a playable build, green tests and a short changelog.**",
  ]),
  H2("18.2 Phases"),
  Tbl(["Phase", "Goal", "Deliverables", "Exit criteria", "Est."], [
    ["0. Foundation", "A clean skeleton that will not need to be rewritten", "Folder structure, autoloads (EventBus, ContentDB, GameState, SaveService, Rng), content loader + validator, test runner, CLAUDE.md, coding standards", "Empty game boots, loads data, validator fails on broken data, tests run in CI/headless", "1–2 w"],
    ["1. Combat core", "Grey-box card combat", "CombatSession (pure), cards as data, effects interpreter, AP, draw/discard, enemy deck + intents, body parts, combat screen", "One full fight playable; bot can play 1000 fights headless", "3–4 w"],
    ["2. Gear = deck", "Equipment builds the deck", "Weapon tablet with grid + polyomino modules, armor sockets, mechanisms, deck assembly, ammo/reload", "Changing modules changes the deck; tests for grid placement", "3 w"],
    ["3. Investigation", "Contracts and rumors", "Tavern board, contract tablet, tracker, map with figure, search ring, rumor tablet, tag matching, outcomes; ContractGenerator + RumorGenerator v1", "Contract → rumor → fight → reward loop works with generated content", "4 w"],
    ["4. Time, city, economy — VERTICAL SLICE", "The day loop", "Calendar, day actions, rent, shop, workshop crafting, library, tavern shift, Hunter's Fall; 3 districts", "Prologue + 1 week playable start-to-end; first external playtest", "3–4 w"],
    ["5. Art generation pipeline (parallel from Phase 1)", "Consistent look", "Style bible, prompt files, city sketch, import tool (PNG → webp, naming check), placeholder → final swap", "Map, 3 districts, UI props and 6 monsters in final style", "ongoing"],
    ["6. Progression", "Long-term goals", "Levels, attributes, Mechanic + Monster skill webs, Voice stages, Bestiary, factions & reputation, Register rank", "A full Chapter I week shows meaningful build choices", "4 w"],
    ["7. Living city", "Districts change", "District state system, transitions, overlays, EventScheduler, all 12 districts in data", "Storm Season and Fog Breach work end-to-end, saved and loaded", "3 w"],
    ["8. Chapter I content", "First complete chapter", "Story contracts, dialogues, 8–10 monsters, 40–60 cards, all Chapter I art", "Chapter I completable; bot finishes it; playtest", "6–8 w"],
    ["9. Chapters II–III", "Full campaign", "Transition Zone + Lower City layers, Ruins, finale, endings, remaining monsters", "Game completable with all endings", "10–12 w"],
    ["10. Polish and release", "Ship it", "Balance pass (bots + humans), audio, VFX, tutorial hints, localisation RU/EN, performance pass, Steam build", "No blockers, stable 60 FPS, all tests green", "6 w"],
  ], [1.1, 1.1, 2.4, 2, 0.5]),
  Note("Estimates assume one developer working with AI assistance. The order matters more than the numbers: never start content production (Phase 8) before the vertical slice (Phase 4) is fun."),
  H2("18.3 Generation track inside the roadmap"),
  Tbl(["Phase", "Procedural generation", "AI art generation"], [
    ["0–1", "Rng service with named streams; seeded tests", "Style bible; 3 test images to lock the style"],
    ["2", "—", "Weapon tablet, module and resource icons"],
    ["3", "ContractGenerator v1, RumorGenerator v1, OutcomeResolver", "City sketch → full city map; rumor diamond, search ring, tavern board, contract tablet"],
    ["4", "ShopGenerator", "Shop table, hero figurine (4 views), 3 district tiles + scenes"],
    ["6", "LootGenerator, MonsterVariant", "Monster silhouettes + cracked versions"],
    ["7", "EventScheduler", "State variants for the 3 slice districts"],
    ["8–9", "Tuning tables by chapter", "All remaining districts, variants, Lower City layers"],
  ], [0.6, 2.2, 2.2]),
];

const architecture = () => [
  H1("19. Technical Architecture (Godot 4.7, GDScript)"),
  H2("19.1 Principles"),
  Tbl(["Principle", "How it is applied"], [
    ["Layered architecture", "Data → Rules → State → Services → Presentation. A layer only depends on layers to its left."],
    ["Single responsibility", "One mechanic = one rules file (`class_name`, static functions) + one test file. One screen = one scene + one script."],
    ["UI never owns logic", "Scenes read state and send **commands** through the GameState facade. They never change RunState directly."],
    ["Pure, deterministic rules", "Rules are static functions of (state, data, rng). No nodes, no globals inside rules. Easy to test and to run in bots."],
    ["Data-driven content", "All content in `data/*.json`, loaded once into typed objects by ContentDB. Validator rejects bad data at start-up."],
    ["Events instead of coupling", "Systems talk through `EventBus` signals (`day_changed`, `district_state_changed`, `card_played`)."],
    ["Composition over inheritance", "Monsters, cards and modules are data + small effect ops, not class hierarchies."],
    ["Open/closed effects", "Card and module effects are data ops (`{\"op\": \"damage\", \"amount\": 6}`) interpreted by EffectApplier. New effect = one new op handler."],
    ["Static typing everywhere", "Typed vars, typed arrays, return types. Write `var x: Type =` when the source is a Variant/Dictionary."],
    ["No magic numbers", "All tuning values in `data/balance.json`."],
    ["Versioned saves", "`SAVE_VERSION` + migration functions; saves are plain dictionaries of RunState."],
    ["KISS / YAGNI", "No framework code 'for later'. Generalise on the second real use, not the first."],
  ], [1.3, 4]),
  H2("19.2 Project structure"),
  Code(`bloody_voice/
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
    bot/autoplay.gd             # balance bot`, 14),
  H2("19.3 Dependency direction"),
  Code(`Presentation (scenes/)  ──commands──>  GameState (facade)  ──calls──>  Rules / Generators
       ^                                        │                              │
       │  signals                               v                              v
   EventBus  <─────────────── emits ─────  RunState (data)  <──── reads ──  ContentDB (data)`, 15),
  P("Rules and generators never import scenes. Scenes never write to RunState. Only GameState mutates state, always by calling rules, then emits signals."),
  H2("19.4 Code samples"),
  H3("EventBus"),
  Code(`# autoload/event_bus.gd
extends Node

signal day_changed(day: int)
signal contract_accepted(contract_id: StringName)
signal rumor_spawned(rumor_id: StringName)
signal district_state_changed(target: StringName, old_state: StringName, new_state: StringName)
signal card_played(card_id: StringName, target: StringName)
signal combat_finished(result: Dictionary)`),
  H3("A rules file (pure, static, typed)"),
  Code(`# core/rules/combat/capture_rules.gd
class_name CaptureRules
extends RefCounted

## Chance to capture a creature. Pure function: no globals, no nodes.
static func chance(card_base: float, hp: int, max_hp: int, cunning: int,
		broken_parts: int, balance: BalanceDef) -> float:
	var missing: float = 1.0 - float(hp) / float(max_hp)
	var bonus: float = (1.0 + balance.capture_per_cunning * cunning) \\
			* (1.0 + balance.capture_per_broken_part * broken_parts)
	return clampf(card_base * missing * bonus, 0.0, balance.capture_max_chance)

static func roll(rng: RandomNumberGenerator, chance_value: float) -> bool:
	return rng.randf() < chance_value`),
  H3("Effects as data"),
  Code(`// data/cards/shock_harpoon.json
{ "id": "shock_harpoon", "type": "attack", "cost": 2, "ammo": 1,
  "target": "enemy_part",
  "effects": [ { "op": "damage", "amount": 7, "kind": "pierce" },
               { "op": "apply_status", "status": "shocked", "turns": 1 } ] }`),
  Code(`# core/rules/combat/effect_applier.gd
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
		_: push_error("Unknown effect op: %s" % op)  # never happens: validator checks OPS at start-up`),
  H3("GameState facade (the only writer of state)"),
  Code(`# autoload/game_state.gd (fragment)
func investigate(rumor_id: StringName) -> void:
	var result: OutcomeResult = OutcomeRules.resolve(run, rumor_id, ContentDB.data)
	run = DayActionRules.spend_day(run, &"investigate")
	EventBus.day_changed.emit(run.calendar.day)
	if result.starts_combat:
		_open_combat(result.encounter)`),
  H3("Seeded RNG streams"),
  Code(`# autoload/rng_service.gd
extends Node

var master_seed: int

func stream(name: StringName, day: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([master_seed, name, day])
	return rng`),
  H2("19.5 Coding standards"),
  Bul([
    "GDScript style guide: tabs, `snake_case` for files/functions/vars, `PascalCase` for classes, `UPPER_CASE` for constants, `&\"ids\"` (StringName) for content ids.",
    "File size budget: **≤ 400 lines** per script, functions **≤ 40 lines**. Split before it grows (lesson from SunLess: 1200-line screens are hard to change).",
    "Every public function has a type signature and a one-line `##` doc comment.",
    "No logic in `_process`; screens refresh on signals and a queued refresh (`_queue_refresh`).",
    "Pool card views and diamond icons; cache derived data in ContentDB (`memo`).",
    "Every new mechanic: rules file + test suite + validator rules + tutorial hint entry.",
    "Content ids are stable: never rename an id that is in a save; add a migration instead.",
    "Commit after every phase step; tests must be green before a commit.",
  ]),
  H2("19.6 Testing and tooling"),
  Tbl(["Tool", "Purpose"], [
    ["tests/run_tests.gd", "Headless test runner, one suite per rules file; also a 'compile all scripts' test"],
    ["content_validator.gd", "Checks ids, references, effect ops, tags, district codes; the game refuses to start on errors"],
    ["tests/bot/autoplay.gd", "Plays fights and whole weeks with simple heuristics; reports win rate, deadlines missed, money curve"],
    ["tools/gen_city_sketch.py", "Regenerates the city sketch, cross-section and ASCII grid from one layout"],
    ["tools/import_art.py", "Imports generated art: checks naming (CODE__state), resizes, converts to webp"],
    ["Auto-screenshots", "`--shots=<dir>` runs scripted scenes and saves PNGs for visual review"],
  ], [1.4, 4]),
  Code(`G="/d/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import
"$G" --headless --path . -s res://tests/run_tests.gd
"$G" --headless --path . -s res://tests/bot/autoplay.gd -- --fights=1000`, 15),
];

const appendices = () => [
  H1("Appendix A. Names and Inspiration Mapping"),
  P("All names in the game are original. This table only records which element of the inspiration each one is based on."),
  Tbl(["In Bloody Voice", "Inspired by (novel element)"], [
    ["Hallowdeep (city)", "Norzin, the capital on a metal platform"],
    ["Aethra (the land)", "Azir"],
    ["The Mistveil", "The Wall of Fog"],
    ["The Underdream / dreamspawn", "The dream realm / dream beasts"],
    ["The Four Elder Mothers (Frost, Ember, Dusk, Root)", "The Four Primordial Witches"],
    ["The Voice / beast blood", "Sordid blood used by hunters; infection in three stages"],
    ["Lumen Collegium, the Lumen Register (A/P/D/S)", "Truth Union and its yearly classification register"],
    ["Order of the Iron Vigil, Vigil Spire", "Secret Rite Tower"],
    ["Crown Magistracy, Crown Ward", "Central administration, Central District"],
    ["Church of the Pale Vault, the Masked Moon", "Church of the Dome, the false moon god"],
    ["The Grey Communion", "Church of Pestilence"],
    ["Rowan Exchange (Harrow / Brannoc / Varga)", "Ash Chamber of Commerce and its three druid families"],
    ["Deepwright Company", "Rolle Resource Development"],
    ["Pale Hounds / Weavers", "Hunter groups White Wolf / Spider"],
    ["Scarlet Supper", "Blood Feast"],
    ["House Morrell", "Sandra clan (arcane medicine)"],
    ["The Dusk Anointed", "The Anointed of Walpurgis Night"],
    ["The Nordhal", "The Northlanders"],
    ["The quiet bookshop on 23rd Avenue", "The protagonist's bookstore (easter egg)"],
  ], [1.5, 2]),

  H1("Appendix B. MVP Monster Roster"),
  Tbl(["Monster", "Rank", "Districts", "Tags", "Body parts", "Notes"], [
    ["Gutter Choir", "A", "AVENUES, SCARLET", "children singing; wet handprints; near water; during rain; drowned in shallow water", "Throats ×3", "Swarm-like; tutorial-level"],
    ["Moth Matron", "A", "SILVERHILL", "dust on sleepers; moonlight; victims never wake; silent wings", "Wings, Body", "Puts Sleep cards in the deck"],
    ["The Lamplighter", "P", "AVENUES, CROWN", "lamps die one by one; too tall; only in fog; burnt eyes", "Lantern, Hands", "Breaking the lantern ends its darkness phase"],
    ["Rust Mantis", "P", "DEEPWRIGHT", "grinding metal; acid burns; foundries; eats machinery", "Scythes ×2, Shell", "Corrodes weapon modules"],
    ["Mourning Bride", "P", "CROWN", "covered mirrors; one guest too many; victim smiling; perfume", "Veil, Mirror", "Copies the hero's last card"],
    ["Vigil Hound", "P", "NORDHAL", "a howl; footprints turn into paws; smell of medicine; former hunter", "Jaw, Legs", "Story: someone from the tavern; capture = save him?"],
    ["Clay Saint", "P", "LUMEN", "formalin; glass chiming; neat surgical wounds; walks in daylight", "Head, Core", "Immune to Fear; weak to Spark"],
    ["Burrow Wyrm", "D", "DEEPWRIGHT, Transition", "tremors; floors collapse; acid; knocking from below", "Maw, Shell, Tail", "Boss of Chapter II opening"],
  ], [1.1, 0.4, 1.1, 2.4, 1, 1.4]),

  H1("Appendix C. Starter Deck and Example Cards"),
  Tbl(["Card", "Type", "Cost", "Effect", "Source"], [
    ["Strike", "Attack", "1", "Deal 6 damage", "Base ×4 (hunting knife)"],
    ["Guard", "Support", "1", "Gain 5 block", "Base ×4"],
    ["Shot", "Attack", "1 + 1 ammo", "Deal 8 damage to a body part", "Weapon frame ×2"],
    ["Reload", "Support", "1", "Restore ammo to full", "Weapon magazine"],
    ["Read the Beast", "Support", "0", "Reveal 1 more enemy intent this turn; Observe a body part", "Base"],
    ["Sidestep", "Support", "1", "Dodge the next attack", "Greaves"],
    ["Shock Harpoon", "Attack", "2 + 1 ammo", "Deal 7 pierce; Shocked 1 turn", "Coil + Harpoon link"],
    ["Flash", "Support", "1", "Enemy loses its next intent if it is a Fear card", "Lantern of Revealing (helmet)"],
    ["Smoke Screen", "Support", "1", "Gain 10 block; enemy intents hidden next turn", "Smoke Bellows (chest)"],
    ["Iron Net", "Capture", "1", "Capture attempt (base 0.6)", "Contract-only"],
    ["Tonic of Morrell", "Consumable", "0", "Heal 12 HP", "Shop"],
    ["Hound's Rage", "Rage", "0", "Deal 12 damage; lose 4 HP", "The Voice (Hound formula)"],
  ], [1.2, 0.9, 0.8, 2.4, 1.6]),

  H1("Appendix D. Glossary"),
  Tbl(["Term", "Meaning"], [
    ["Contract", "A job from the tavern board: slay, capture, research or story"],
    ["Rumor / diamond", "A lead that appears in the search ring; may be true, wrong, false or empty"],
    ["Tag", "A sign of a monster (sound, trace, victims, time, place, shape)"],
    ["Search ring", "Blue aura spreading from the hero figure in a district; grows daily"],
    ["Tablet", "In-world UI panel (contract, rumor, weapon)"],
    ["Module", "A shaped part installed into weapon cells; gives cards and bonuses"],
    ["Mechanism", "A device installed into an armor socket; gives tags and cards"],
    ["Blueprint", "Recipe for crafting a module, mechanism, weapon or armor piece"],
    ["The Voice", "Corruption from beast blood; 3 stages"],
    ["District state", "Current condition of a district/area/landmark (normal, flooded, burned…)"],
    ["Register rank", "Public danger rank A/P/D/S of beings and places"],
    ["Hunter's Fall", "Defeat in combat: clinic, losses, Scar (not game over unless Ironman)"],
  ], [1.2, 4]),
];

module.exports = { generation, roadmap, architecture, appendices };
