extends TestSuite
## The notebook of rumors (GDD 8.4): overhearing on the way, asking in the tavern, threads from signs to contracts
## (held: the sign is learned; snapped: the card burns), the lair, throwing away, the morning tidy-up, Cunning, saves.


## A run with the first leaflet of the board taken.
func _run(data: ContentData, seed_value: int = 7) -> RunState:
	var run := RunState.create(seed_value, data.balance)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(seed_value, &"contracts", 1))
	ContractRules.accept(run.contracts, data, ContractRules.board(run.contracts)[0].uid)
	return run


func _contract(run: RunState) -> ContractsState.Contract:
	return ContractRules.active(run.contracts)[0]


## A right card about the contract's creature, put in the notebook (`lie`: one false sign mixed in).
func _right(data: ContentData, run: RunState, lie: StringName = &"") -> RumorsState.Card:
	var c := _contract(run)
	var card := RumorGenerator.make(data, run.hero_district, c.zone, c, [], run.rumors.next_uid, run.day,
		SeededRng.make_stream(run.rumors.next_uid, &"t", 1))
	run.rumors.next_uid += 1
	card.lies.clear()
	card.tags.assign(card.tags.filter(func(t: StringName) -> bool: return data.monster(c.monster).tags.has(t)))
	if lie != &"":
		card.tags.append(lie)
		card.lies.append(lie)
	run.rumors.cards.append(card)
	return card


func _wrong(run: RunState) -> RumorsState.Card:
	var card := RumorsState.Card.new()
	card.uid = run.rumors.next_uid
	run.rumors.next_uid += 1
	card.zone = _contract(run).zone
	card.tags = _contract(run).known_tags.duplicate()
	card.lies = card.tags.duplicate()
	run.rumors.cards.append(card)
	return card


func _lie(data: ContentData, c: ContractsState.Contract) -> StringName:
	for tag: StringName in data.tags:
		if not data.monster(c.monster).tags.has(tag) and not c.known_tags.has(tag):
			return tag
	return &""


func test_overhearing_on_the_way() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var got: Array[RumorsState.Card] = []
	for i: int in 200:
		var card := RumorRules.overhear(run, data, c.zone, SeededRng.make_stream(i, &"overhear", 1))
		if card != null:
			got.append(card)
			eq(card.zone, c.zone, "about the zone the hunter walks")
			check(not card.tags.is_empty() and card.witness != &"" and card.fresh, "signs, a witness, new")
			check(not card.right() or card.monster == c.monster, "a right card is about the contract's creature")
	eq(got.size(), RumorRules.per_day(run, data), "no more than overhear_per_day a day")
	eq(run.rumors.rolls, 200, "every roll counts")
	check(RumorRules.overhear(run, data, &"", SeededRng.make_stream(1, &"o", 1)) == null, "nothing outside the zones")
	run.day += 1
	var next: RumorsState.Card = null
	for i: int in 50:
		next = RumorRules.overhear(run, data, c.zone, SeededRng.make_stream(500 + i, &"overhear", 2))
		if next != null:
			break
	check(next != null, "a new day, new rumors")


func test_asking_in_the_tavern_once_a_day() -> void:
	var data := load_content(false)
	var run := _run(data)
	var b := data.balance.rumors
	var cards := RumorRules.ask(run, data, &"tavern", SeededRng.make_stream(3, &"ask", 1))
	check(cards.size() >= b.ask_min and cards.size() <= b.ask_max, "2-3 rumors (%d)" % cards.size())
	eq(run.rumors.cards.size(), cards.size(), "they are in the notebook")
	check(RumorRules.can_ask(run, data, &"tavern") != "", "once a day")
	eq(RumorRules.ask(run, data, &"tavern", SeededRng.make_stream(4, &"ask", 1)).size(), 0, "nothing the second time")
	run.day += 1
	check(RumorRules.can_ask(run, data, &"tavern") == "", "again tomorrow")


func test_a_full_notebook_takes_no_more() -> void:
	var data := load_content(false)
	var run := _run(data)
	for i: int in data.balance.rumors.notebook_max:
		_wrong(run)
	check(RumorRules.notebook_full(run, data), "full")
	check(RumorRules.can_ask(run, data, &"tavern") != "", "no asking")
	for i: int in 30:
		check(RumorRules.overhear(run, data, _contract(run).zone, SeededRng.make_stream(i, &"o", 1)) == null, "no overhearing")


func test_true_threads_hold_and_bring_the_lair() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var needed := data.balance.rumors.trail_needed
	var l: RumorRules.Link = null
	for i: int in needed:
		var card := _right(data, run)
		l = RumorRules.link(run, data, card.uid, c.uid, card.tags[0], SeededRng.make_stream(i, &"lair", 1))
		check(l != null and l.held, "a true sign holds")
		eq(l.trail, i + 1, "the trail grows by a card")
		check(c.known_tags.has(card.tags[0]), "the contract knows the sign")
		eq(card.linked, c.uid, "the card is on the thread")
	check(l.mark != null and l.mark.contract_uid == c.uid and l.mark.monster == c.monster, "the lair at the goal")
	eq(RumorRules.target_mark(run.rumors, c.uid), l.mark, "found by its contract")
	var more := _right(data, run)
	var again := RumorRules.link(run, data, more.uid, c.uid, more.tags[0], SeededRng.make_stream(9, &"lair", 1))
	check(again.held and again.mark == null, "no second lair")


func test_false_threads_snap_and_burn_the_card() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var wrong := _wrong(run)
	var l := RumorRules.link(run, data, wrong.uid, c.uid, wrong.tags[0], SeededRng.make_stream(1, &"lair", 1))
	check(l != null and not l.held, "a rumor about something else snaps")
	check(run.rumors.card(wrong.uid) == null, "and burns")
	var lie := _lie(data, c)
	var noisy := _right(data, run, lie)
	l = RumorRules.link(run, data, noisy.uid, c.uid, lie, SeededRng.make_stream(2, &"lair", 1))
	check(not l.held and not c.known_tags.has(lie), "a lie on a right card snaps too and is never learned")
	eq(run.rumors.trail(c.uid), 0, "no trail")


func test_what_cannot_be_tied() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var card := _right(data, run)
	check(RumorRules.link(run, data, 9999, c.uid, &"howl", SeededRng.make_stream(1, &"l", 1)) == null, "no such card")
	check(RumorRules.link(run, data, card.uid, 9999, card.tags[0], SeededRng.make_stream(1, &"l", 1)) == null, "no such contract")
	check(RumorRules.link(run, data, card.uid, c.uid, &"not_its_sign", SeededRng.make_stream(1, &"l", 1)) == null, "not its sign")
	RumorRules.link(run, data, card.uid, c.uid, card.tags[0], SeededRng.make_stream(1, &"l", 1))
	check(RumorRules.link(run, data, card.uid, c.uid, card.tags[0], SeededRng.make_stream(1, &"l", 1)) == null, "not twice")


func test_throwing_away_seen_and_tidy() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	var wrong := _wrong(run)
	var tied := _right(data, run)
	RumorRules.link(run, data, tied.uid, c.uid, tied.tags[0], SeededRng.make_stream(1, &"l", 1))
	check(not RumorRules.discard(run, tied.uid), "a card on a thread stays")
	check(RumorRules.discard(run, wrong.uid) and run.rumors.card(wrong.uid) == null, "a loose card goes")
	check(run.rumors.fresh_count() > 0 and RumorRules.seen(run), "new cards are seen")
	eq(run.rumors.fresh_count(), 0, "none new now")
	check(not RumorRules.tidy(run), "nothing to tidy while the contract is open")
	c.done = true
	check(RumorRules.tidy(run) and run.rumors.cards.is_empty(), "the closed contract's cards go")


func test_cunning() -> void:
	var data := load_content(false)
	var run := _run(data)
	var wrong := _wrong(run)
	run.progress.attributes[&"cunning"] = ceili(1.0 / data.balance.progress.flag_per_cunning)
	check(ProgressRules.suspicious(run, data, wrong), "enough Cunning always senses a wrong rumor")
	check(not ProgressRules.suspicious(run, data, _right(data, run)), "never on a right one")
	run.progress.attributes[&"cunning"] = 0
	check(not ProgressRules.suspicious(run, data, wrong), "no Cunning, no whisper")


func test_notebook_survives_save_and_old_saves_migrate() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := _contract(run)
	for i: int in data.balance.rumors.trail_needed:
		var card := _right(data, run)
		RumorRules.link(run, data, card.uid, c.uid, card.tags[0], SeededRng.make_stream(i, &"l", 1))
	_wrong(run)
	RumorRules.ask(run, data, &"tavern", SeededRng.make_stream(3, &"ask", 1))
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.rumors.to_dict(), run.rumors.to_dict(), "round trip")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 18, "master_seed": 9, "day": 3,
		"rumors": {"marks": [{"uid": 1, "kind": "threat"}], "trails": {"1": 2}, "threats": {}, "next_uid": 2}}))
	check(old.rumors.cards.is_empty() and old.rumors.marks.is_empty(), "v18: listening is dropped")


func test_same_seed_same_card() -> void:
	var data := load_content(false)
	var a := RumorRules.ask(_run(data, 31), data, &"tavern", SeededRng.make_stream(5, &"ask", 1))
	var b := RumorRules.ask(_run(data, 31), data, &"tavern", SeededRng.make_stream(5, &"ask", 1))
	eq(a.map(func(c: RumorsState.Card) -> Dictionary: return c.to_dict()),
		b.map(func(c: RumorsState.Card) -> Dictionary: return c.to_dict()), "deterministic")
