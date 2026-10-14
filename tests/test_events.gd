extends TestSuite
## District events (GDD 14, 15): the Monday roll, the state an event brings, what the state changes (prices, pay,
## rewards, rumors, creatures, shut places), the news leaflets, the end of an event and the rest weeks, saves.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(31, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	return run


func _monday(data: ContentData, week: int) -> int:
	return (week - 1) * data.balance.days_per_week + 1


func _start(run: RunState, data: ContentData, id: StringName) -> void:
	EventRules.start(run, data, data.event(id), SeededRng.make_stream(1, &"events", 1))


func test_no_event_in_the_first_week_and_once_a_week() -> void:
	var data := load_content(false)
	var run := _run(data)
	data.balance.events.chance = 1.0
	check(EventRules.weekly(run, data, SeededRng.make_stream(1, &"events", 1)) == null, "week 1 is quiet")
	run.day = _monday(data, data.balance.events.first_week)
	var change := EventRules.weekly(run, data, SeededRng.make_stream(1, &"events", 2))
	check(change != null, "an event on the first Monday allowed")
	eq(change.key, run.hero_district, "in the hero's district")
	check(run.events.active != &"", "active")
	eq(run.city.state_of(run.hero_district), data.event(run.events.active).state, "the district is in its state")
	eq(EventRules.next_news(run), "%s:start" % run.events.active, "a news leaflet")
	check(EventRules.weekly(run, data, SeededRng.make_stream(1, &"events", 2)) == null, "once a week")


func test_a_save_loaded_mid_week_waits_for_monday() -> void:
	var data := load_content(false)
	var run := _run(data)
	data.balance.events.chance = 1.0
	run.day = _monday(data, 3) + 2
	check(EventRules.weekly(run, data, SeededRng.make_stream(1, &"events", 3)) == null, "not on a Wednesday")


func test_state_effects() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.hero_hp = 1
	var cost := HealthRules.treat_cost(run, data)
	_start(run, data, &"grey_plague")
	check(HealthRules.treat_cost(run, data) > cost, "the plague raises infirmary prices")
	check(EventRules.is_closed(run, data, &"shift"), "no tavern shifts in quarantine")
	run.city = CityState.new()
	run.events = EventsState.new()
	_start(run, data, &"fog_breach")
	var setup := DeckBuilder.default_setup(data, &"gutter_choir", 1)
	EventRules.strengthen(setup, run, data)
	check(setup.enemy_hp_mult > 1.0 and setup.enemy_damage_bonus > 0, "the fog makes creatures stronger")
	run.city = CityState.new()
	_start(run, data, &"dusk_night")
	var t := data.balance.tavern
	var r := ShiftRules.work(run, data, SeededRng.make_stream(1, &"shift", 1))
	check(r.money >= roundi(t.shift_money_min * EventRules.state_def(run, data).shift_pay_mult), "a festival shift pays more")
	eq(EventRules.state_def(run, data).rumor_bonus, 1, "a noisier festival")


func test_prices_rewards_and_rumors_follow_the_state() -> void:
	var data := load_content(false)
	var run := _run(data)
	var x := ShopState.Item.new()
	x.price = 100
	var normal_price := ShopRules.price(run, data, x)
	run.hero_district = &"GREY"
	var calm := RunState.create(31, data.balance)
	ContractRules.refresh_board(calm, data, SeededRng.make_stream(5, &"contracts", 1))
	_start(run, data, &"fog_breach")
	check(ShopRules.price(run, data, x) > normal_price, "the fog raises shop prices")
	ContractRules.refresh_board(run, data, SeededRng.make_stream(5, &"contracts", 1))
	var a := ContractRules.board(calm.contracts)
	var b := ContractRules.board(run.contracts)
	check(a.size() == b.size() and b[0].reward >= a[0].reward, "leaflets pinned in the fog pay more")
	run.city = CityState.new()
	_start(run, data, &"dusk_night")
	var quiet := RunState.create(31, data.balance)
	check(RumorRules.max_heard(run, data) > RumorRules.max_heard(quiet, data), "a festival street holds more rumors")


func test_event_ends_with_news_and_rest_weeks() -> void:
	var data := load_content(false)
	var run := _run(data)
	data.balance.events.chance = 1.0
	run.day = _monday(data, 2)
	_start(run, data, &"dusk_night")
	EventRules.read_news(run)
	var ended := false
	for i: int in 10:
		var changes := DistrictStateRules.tick(run.city, data.district_states)
		run.day += 1
		if EventRules.after_tick(run, data, changes):
			ended = true
			break
	check(ended, "the festival ends")
	eq(run.city.state_of(run.hero_district), &"normal", "back to normal")
	eq(EventRules.next_news(run), "dusk_night:end", "an end leaflet")
	run.events.checked_week = 0
	run.day = _monday(data, run.events.ended_week + data.balance.events.rest_weeks)
	check(EventRules.weekly(run, data, SeededRng.make_stream(1, &"events", 9)) == null, "a rest week")


func test_events_survive_save_and_v13_starts_quiet() -> void:
	var data := load_content(false)
	var run := _run(data)
	_start(run, data, &"fog_breach")
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.events.active, &"fog_breach", "the event kept")
	eq(back.events.news, run.events.news, "unread news kept")
	eq(back.city.state_of(back.hero_district), &"fog_breach", "the state kept")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 13, "master_seed": 4}))
	eq(old.events.active, &"", "v13: no event")
