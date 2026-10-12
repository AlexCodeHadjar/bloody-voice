extends TestSuite
## Tavern contracts (GDD 7, 17.2): the Monday board, accepting, deadlines, overdue creatures, rewards, saves.


func _new_run(data: ContentData, seed_value: int = 5) -> RunState:
	var run := RunState.create(seed_value, data.balance)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(seed_value, &"contracts", 1))
	return run


func test_board_follows_the_rules() -> void:
	var data := load_content(false)
	var c := data.balance.contracts
	var run := _new_run(data)
	var board := ContractRules.board(run.contracts)
	check(board.size() >= c.board_min and board.size() <= c.board_max, "board size %d" % board.size())
	eq(run.contracts.board_week, 1, "filled for week 1")
	var pool := EncounterRules.pool(data, &"GREY")
	check(not pool.is_empty(), "creatures live in GREY")
	for x: ContractsState.Contract in board:
		var m := data.monster(x.monster)
		check(pool.has(x.monster), "%s lives in GREY" % x.monster)
		check(x.known_tags.size() >= c.known_tags_min and x.known_tags.size() <= c.known_tags_max, "known tags count")
		for t: StringName in x.known_tags:
			check(m.tags.has(t), "known tag %s is the creature's own" % t)
		var left := ContractRules.days_left(x, run.day)
		check(left >= c.deadline_min and left <= c.deadline_max, "deadline %d" % left)
		check(x.reward > 0 and x.reward % c.reward_step == 0, "reward %d" % x.reward)
		check(data.petition(x.petition).types.has(x.type), "petition fits the type")
		check(data.district_map(&"GREY").zones.any(func(z: DistrictMapDef.ZoneDef) -> bool: return z.id == x.zone), "zone")
	check(not ContractRules.refresh_board(run, data, SeededRng.make_stream(5, &"contracts", 1)), "same week: no refill")


func test_same_seed_same_board() -> void:
	var data := load_content(false)
	var a := ContractRules.board(_new_run(data, 42).contracts)
	var b := ContractRules.board(_new_run(data, 42).contracts)
	eq(a.size(), b.size(), "size")
	for i: int in a.size():
		eq(a[i].to_dict(), b[i].to_dict(), "leaflet %d" % i)


func test_accept_and_the_limit_of_open_contracts() -> void:
	var data := load_content(false)
	var run := _new_run(data)
	var board := ContractRules.board(run.contracts)
	eq(ContractRules.accept(run.contracts, data, board[0].uid), "", "first accept")
	check(ContractRules.accept(run.contracts, data, board[0].uid) != "", "cannot take twice")
	check(ContractRules.accept(run.contracts, data, 9999) != "", "unknown uid")
	for x: ContractsState.Contract in board:
		ContractRules.accept(run.contracts, data, x.uid)
	eq(ContractRules.active(run.contracts).size(), mini(board.size(), data.balance.contracts.max_active), "capped")


func test_monday_keeps_taken_contracts_and_replaces_the_rest() -> void:
	var data := load_content(false)
	var run := _new_run(data)
	var taken := ContractRules.board(run.contracts)[0]
	ContractRules.accept(run.contracts, data, taken.uid)
	run.day += data.balance.days_per_week
	check(ContractRules.refresh_board(run, data, SeededRng.make_stream(5, &"contracts", 2)), "new week: new board")
	check(run.contracts.find(taken.uid) != null, "the taken contract stays")
	var uids := {}
	for x: ContractsState.Contract in run.contracts.items:
		check(x == taken or (x.week == 2 and not x.accepted), "old leaflets are gone")
		check(not uids.has(x.uid), "uids are unique")
		uids[x.uid] = true
	check(not ContractRules.board(run.contracts).has(taken), "last week's leaflet is not on this week's board")


func test_fight_outcomes_and_rewards() -> void:
	var data := load_content(false)
	var run := _new_run(data)
	var x := ContractRules.board(run.contracts)[0]
	eq(ContractRules.reward_for(x, &"slain"), 0, "not taken: no reward")
	ContractRules.accept(run.contracts, data, x.uid)
	x.type = &"capture"
	eq(ContractRules.reward_for(x, &"slain"), 0, "a capture needs the creature alive")
	eq(ContractRules.reward_for(x, &"captured"), x.reward, "captured")
	x.type = &"slay"
	eq(ContractRules.reward_for(x, &"fallen"), 0, "lost fight")
	var money := run.money
	eq(ContractRules.resolve_fight(run, x.uid, &"slain"), x.reward, "paid")
	eq(run.money, money + x.reward, "money")
	check(x.done and ContractRules.active(run.contracts).is_empty(), "finished")
	eq(ContractRules.resolve_fight(run, x.uid, &"slain"), 0, "never paid twice")


func test_overdue_contract_makes_the_creature_stronger() -> void:
	var data := load_content(false)
	var run := _new_run(data)
	var x := ContractRules.board(run.contracts)[0]
	ContractRules.accept(run.contracts, data, x.uid)
	var reward := x.reward
	var setup := DeckBuilder.default_setup(data, x.monster, 3)
	ContractRules.prepare_fight(setup, x, x.deadline_day, data.balance)
	eq(setup.enemy_hp_mult, 1.0, "on the last day: normal")
	ContractRules.prepare_fight(setup, x, x.deadline_day + 1, data.balance)
	var s := CombatRules.start(setup, data)
	var b := data.balance
	eq(s.contract_uid, x.uid, "the fight knows its contract")
	eq(s.enemy.max_hp, ceili(data.monster(x.monster).hp * b.contracts.overdue_hp_mult), "more hp")
	eq(s.enemy.hp, s.enemy.max_hp, "full hp")
	eq(DamageRules.compute(5, s.enemy, s.hero, b), 5 + b.contracts.overdue_damage_bonus, "harder hits")
	eq(x.reward, reward, "the reward does not grow")


func test_contracts_survive_save_and_old_saves_get_an_empty_board() -> void:
	var data := load_content(false)
	var run := _new_run(data)
	ContractRules.accept(run.contracts, data, ContractRules.board(run.contracts)[0].uid)
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.contracts.to_dict(), run.contracts.to_dict(), "round trip")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 3, "master_seed": 9, "day": 10}))
	eq(old.contracts.items.size(), 0, "v3 save: no contracts yet")
	check(ContractRules.refresh_board(old, data, SeededRng.make_stream(9, &"contracts", 2)), "filled on load")
