extends TestSuite
## Listening for rumors (GDD 8.4): heard rumors in a zone, right ones grow a contract's trail and teach its signs, wrong
## ones bring an unknown threat, marks, the morning tidy-up, Cunning's whisper, saves.


## A run with the first leaflet of the board taken.
func _run(data: ContentData, seed_value: int = 7) -> RunState:
	var run := RunState.create(seed_value, data.balance)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(seed_value, &"contracts", 1))
	ContractRules.accept(run.contracts, data, ContractRules.board(run.contracts)[0].uid)
	return run


func _contract(run: RunState) -> ContractsState.Contract:
	return ContractRules.active(run.contracts)[0]


## A right rumor about the contract's creature (`lie`: one false sign mixed in).
func _right(data: ContentData, run: RunState, uid: int, lie: StringName = &"") -> RumorGenerator.Heard:
	var c := _contract(run)
	var h := RumorGenerator.make(data, run.hero_district, c.zone, c, [], [], uid, SeededRng.make_stream(uid, &"t", 1))
	h.lies.clear()
	if lie != &"":
		h.tags.append(lie)
		h.lies.append(lie)
	return h


func _wrong(run: RunState, zone: StringName, uid: int) -> RumorGenerator.Heard:
	var h := RumorGenerator.Heard.new()
	h.uid = uid
	h.zone = zone
	h.tags = [&"howl"]
	h.lies = [&"howl"]
	return h


func test_heard_rumors_in_a_contract_zone() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var map := data.district_map(run.hero_district)
	var right := 0
	var wrong := 0
	for i: int in 60:
		var h := RumorRules.hear(run, data, c.zone, [], SeededRng.make_stream(i, &"listen", 1))
		if h == null:
			continue
		eq(DistrictMapRules.zone_at(map, map.node_pos(h.node)), c.zone, "it flares up in the zone")
		check(not h.tags.is_empty() and h.witness != &"", "signs and a witness")
		if h.right():
			right += 1
			eq(h.monster, c.monster, "a right rumor is about the contract's creature")
			eq(h.contract_uid, c.uid, "and names the contract")
		else:
			wrong += 1
			check(h.monster != c.monster, "a wrong rumor is never about the contract's creature")
	check(right > 0 and wrong > 0, "both right and wrong rumors are heard (%d / %d)" % [right, wrong])


func test_no_right_rumor_without_a_contract_in_the_zone() -> void:
	var data := load_content(false)
	var run := _run(data)
	var map := data.district_map(run.hero_district)
	var other := &""
	for z: DistrictMapDef.ZoneDef in map.zones:
		if z.id != _contract(run).zone:
			other = z.id
	for i: int in 20:
		var h := RumorRules.hear(run, data, other, [], SeededRng.make_stream(i, &"listen", 1))
		check(h == null or not h.right(), "nothing right to hear in %s" % other)


func test_right_rumors_follow_the_trail() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var needed := data.balance.rumors.trail_needed
	var lie := &""
	for tag: StringName in data.tags:
		if not data.monster(c.monster).tags.has(tag) and not c.known_tags.has(tag):
			lie = tag
	var t: RumorRules.Taken = null
	for i: int in needed:
		t = RumorRules.take(run, data, _right(data, run, 100 + i, lie), SeededRng.make_stream(i, &"take", 1))
		check(t.right, "a right rumor")
		eq(run.rumors.trail(c.uid), i + 1, "the trail grows")
	check(not c.known_tags.has(lie), "a lie is never learned")
	check(t.mark != null and t.mark.kind == &"target", "the creature's mark at the goal")
	eq(RumorRules.target_mark(run.rumors, c.uid), t.mark, "found by its contract")
	eq(t.mark.monster, c.monster, "the contract's creature")
	var more := RumorRules.take(run, data, _right(data, run, 200), SeededRng.make_stream(9, &"take", 1))
	eq(run.rumors.trail(c.uid), needed, "a found creature's trail stops")
	check(more.mark == null and more.right, "no second mark")


func test_wrong_rumors_bring_an_unknown_threat() -> void:
	var data := load_content(false)
	var run := _run(data)
	var zone := _contract(run).zone
	var t: RumorRules.Taken = null
	for i: int in data.balance.rumors.threat_needed:
		t = RumorRules.take(run, data, _wrong(run, zone, 300 + i), SeededRng.make_stream(i, &"take", 1))
		check(not t.right and t.contract_uid == 0, "a wrong rumor grows no trail")
	check(t.mark != null and t.mark.kind == &"threat", "a red threat at the goal")
	eq(t.mark.expires_day, run.day + data.balance.rumors.threat_days, "it fades in threat_days")
	check(EncounterRules.pool(data, run.hero_district).has(t.mark.monster), "any creature of the district")
	check(not run.rumors.threats.has(zone), "the hidden count starts again")


func test_marks_fight_and_tidy() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	for i: int in data.balance.rumors.trail_needed:
		RumorRules.take(run, data, _right(data, run, 400 + i), SeededRng.make_stream(i, &"take", 1))
	for i: int in data.balance.rumors.threat_needed:
		RumorRules.take(run, data, _wrong(run, c.zone, 500 + i), SeededRng.make_stream(i, &"take", 1))
	eq(run.rumors.marks.size(), 2, "a creature and a threat")
	var target := RumorRules.target_mark(run.rumors, c.uid)
	eq(RumorRules.engage(run, target.uid), target, "the creature's mark")
	check(run.rumors.find(target.uid) != null, "stays while its contract is open")
	var threat := run.rumors.marks[1]
	eq(RumorRules.engage(run, threat.uid), threat, "the threat's mark")
	check(run.rumors.find(threat.uid) == null, "a threat goes once fought")
	check(RumorRules.engage(run, 9999) == null, "unknown mark")
	check(not RumorRules.tidy(run), "nothing to tidy yet")
	c.done = true
	check(RumorRules.tidy(run), "the closed contract's mark goes")
	check(run.rumors.marks.is_empty() and not run.rumors.trails.has(c.uid), "with its trail")


func test_threats_fade() -> void:
	var data := load_content(false)
	var run := _run(data)
	for i: int in data.balance.rumors.threat_needed:
		RumorRules.take(run, data, _wrong(run, _contract(run).zone, 600 + i), SeededRng.make_stream(i, &"take", 1))
	run.day += data.balance.rumors.threat_days - 1
	check(not RumorRules.tidy(run), "still there the day before")
	run.day += 1
	check(RumorRules.tidy(run) and run.rumors.marks.is_empty(), "gone on its last morning")


func test_matches_and_cunning() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var h := _wrong(run, c.zone, 700)
	h.tags.assign(c.known_tags)
	eq(RumorRules.matches(h, c), c.known_tags.size(), "all known signs match")
	run.progress.attributes[&"cunning"] = ceili(1.0 / data.balance.progress.flag_per_cunning)
	check(ProgressRules.suspicious(run, data, h), "enough Cunning always senses a wrong rumor")
	check(not ProgressRules.suspicious(run, data, _right(data, run, 701)), "never on a right rumor")
	run.progress.attributes[&"cunning"] = 0
	check(not ProgressRules.suspicious(run, data, h), "no Cunning, no whisper")


func test_rumors_survive_save_and_old_saves_migrate() -> void:
	var data := load_content(false)
	var run := _run(data)
	for i: int in data.balance.rumors.trail_needed:
		RumorRules.take(run, data, _right(data, run, 800 + i), SeededRng.make_stream(i, &"take", 1))
	RumorRules.take(run, data, _wrong(run, &"fog_hollow", 900), SeededRng.make_stream(1, &"take", 1))
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.rumors.to_dict(), run.rumors.to_dict(), "round trip")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 17, "master_seed": 9, "day": 3,
		"rumors": {"items": [{"uid": 1, "kind": "target"}], "next_uid": 2, "last_day": 3}}))
	check(old.rumors.marks.is_empty() and old.rumors.trails.is_empty(), "v17: the old diamonds are dropped")


func test_same_seed_same_rumor() -> void:
	var data := load_content(false)
	var a := RumorRules.hear(_run(data, 31), data, _contract(_run(data, 31)).zone, [], SeededRng.make_stream(5, &"l", 1))
	var b := RumorRules.hear(_run(data, 31), data, _contract(_run(data, 31)).zone, [], SeededRng.make_stream(5, &"l", 1))
	eq([a.node, a.monster, a.tags], [b.node, b.monster, b.tags], "deterministic")
