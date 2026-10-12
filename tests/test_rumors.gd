extends TestSuite
## Rumors (GDD 8, 17.2): the morning's diamonds, true rumors of contracts, lifetime, outcomes, crossed-out signs, saves.


func _run(data: ContentData, seed_value: int = 7) -> RunState:
	var run := RunState.create(seed_value, data.balance)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(seed_value, &"contracts", 1))
	RumorRules.new_morning(run, data, SeededRng.make_stream(seed_value, &"rumors", run.day))
	return run


func _rumor(kind: StringName, tags: Array[StringName], lies: Array[StringName], monster: StringName = &"") -> RumorsState.Rumor:
	var r := RumorsState.Rumor.new()
	r.uid = 900
	r.kind = kind
	r.tags = tags
	r.lies = lies
	r.monster = monster
	r.money = 7
	r.expires_day = 99
	return r


func test_morning_diamonds() -> void:
	var data := load_content(false)
	var b := data.balance.rumors
	var run := _run(data)
	var list := RumorRules.visible(run.rumors)
	check(list.size() >= b.new_min and list.size() <= b.new_max, "1-2 rumors on the first morning (%d)" % list.size())
	var map := data.district_map(&"GREY")
	var nodes := {}
	for r: RumorsState.Rumor in list:
		check(map.zone(r.zone) != null, "zone %s exists" % r.zone)
		check(map.has_node_id(r.node), "node %s exists" % r.node)
		check(not nodes.has(r.node), "one diamond per node")
		nodes[r.node] = true
		eq(r.expires_day, run.day + b.lifetime_days, "lifetime")
		check(r.kind != &"target", "no target rumors without a contract")
		check(not r.tags.is_empty() and data.rumor_data.zone(&"GREY", r.zone).art.has(r.art), "tags and a picture")
	check(not RumorRules.new_morning(run, data, SeededRng.make_stream(7, &"rumors", run.day)), "once per morning")


func test_taken_contract_seeds_a_true_rumor_at_once() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := ContractRules.board(run.contracts)[0]
	ContractRules.accept(run.contracts, data, c.uid)
	check(RumorRules.seed_targets(run, data, SeededRng.make_stream(1, &"t", 1)), "seeded")
	var targets := RumorRules.visible(run.rumors).filter(func(r: RumorsState.Rumor) -> bool: return r.kind == &"target")
	eq(targets.size(), 1, "one true rumor")
	var r := targets[0] as RumorsState.Rumor
	eq(r.monster, c.monster, "about the contract's creature")
	eq(r.contract_uid, c.uid, "linked to the contract")
	for t: StringName in r.tags:
		check(data.monster(c.monster).tags.has(t) or r.lies.has(t), "true tags or a marked lie")
	var gap := c.next_rumor_day - run.day
	check(gap >= data.balance.rumors.true_every_min and gap <= data.balance.rumors.true_every_max, "next true rumor in 2-3 days")
	check(not RumorRules.seed_targets(run, data, SeededRng.make_stream(2, &"t", 1)), "not twice")


func test_rumors_cool_and_the_map_has_a_cap() -> void:
	var data := load_content(false)
	var b := data.balance.rumors
	var run := _run(data)
	var first := RumorRules.visible(run.rumors)[0]
	for i: int in b.lifetime_days:
		run.day += 1
		RumorRules.new_morning(run, data, SeededRng.make_stream(7, &"rumors", run.day))
		check(RumorRules.visible(run.rumors).size() <= b.max_on_map, "cap on day %d" % run.day)
	check(run.rumors.find(first.uid) == null, "the first rumor cooled after %d days" % b.lifetime_days)


func test_outcomes_without_a_fight() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := ContractRules.board(run.contracts)[0]
	ContractRules.accept(run.contracts, data, c.uid)
	var own: StringName = data.monster(c.monster).tags[0]
	var foreign: StringName = RumorGenerator.all_tags(data).filter(func(t: StringName) -> bool: return not data.monster(c.monster).tags.has(t))[0]
	var r := _rumor(&"false_lead", [own, foreign], [own, foreign])
	run.rumors.items.append(r)
	var money := run.money
	var o := RumorRules.investigate(run, data, r.uid)
	eq(o.monster, &"", "no fight")
	eq(run.money, money + 7, "a little money")
	eq(o.crossed, foreign, "the foreign sign is crossed out, never the creature's own")
	check(c.crossed_tags.has(foreign) and not c.crossed_tags.has(own), "on the contract")
	check(RumorRules.investigate(run, data, r.uid) == null, "a rumor is investigated once")


func test_fight_outcomes() -> void:
	var data := load_content(false)
	var run := _run(data)
	var monster: StringName = EncounterRules.pool(data, &"GREY")[0]
	var r := _rumor(&"wrong_monster", [], [], monster)
	run.rumors.items.append(r)
	var money := run.money
	var o := RumorRules.investigate(run, data, r.uid)
	eq(o.monster, monster, "a fight with the creature")
	eq(run.money, money, "no money before the fight")
	check(RumorRules.visible(run.rumors).filter(func(x: RumorsState.Rumor) -> bool: return x.uid == r.uid).is_empty(), "gone from the map")


func test_match_line_and_best_contract() -> void:
	var data := load_content(false)
	var run := _run(data)
	var board := ContractRules.board(run.contracts)
	ContractRules.accept(run.contracts, data, board[0].uid)
	ContractRules.accept(run.contracts, data, board[1].uid)
	var r := _rumor(&"empty_night", board[1].known_tags.duplicate(), [])
	eq(RumorRules.matches(r, board[1]), board[1].known_tags.size(), "all known signs match")
	if board[0].monster != board[1].monster:
		eq(RumorRules.best_contract(run.contracts, r), board[1], "the contract with more matches")


func test_rumors_survive_save_and_old_saves_migrate() -> void:
	var data := load_content(false)
	var run := _run(data)
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.rumors.to_dict(), run.rumors.to_dict(), "round trip")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 4, "master_seed": 9, "day": 3}))
	eq(old.rumors.items.size(), 0, "v4 save: no rumors yet")
	check(RumorRules.new_morning(old, data, SeededRng.make_stream(9, &"rumors", 3)), "filled on load")


func test_same_seed_same_rumors() -> void:
	var data := load_content(false)
	eq(_run(data, 31).rumors.to_dict(), _run(data, 31).rumors.to_dict(), "deterministic")
