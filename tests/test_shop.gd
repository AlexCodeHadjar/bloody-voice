extends TestSuite
## The shop, the bag, the tavern shift and rent debt (GDD 11.1, 3.2–3.3).


func _run(data: ContentData) -> RunState:
	var run := RunState.create(4, data.balance)
	WorkshopRules.ensure_start(run, data)
	ShopRules.refresh(run, data, SeededRng.make_stream(4, &"shop", 1))
	return run


func _first(run: RunState, kind: StringName) -> ShopState.Item:
	for x: ShopState.Item in run.shop.items:
		if x.kind == kind:
			return x
	return null


func test_weekly_table_follows_the_slots() -> void:
	var data := load_content(false)
	var run := _run(data)
	for kind: StringName in data.balance.shop.slots:
		var n := run.shop.items.filter(func(x: ShopState.Item) -> bool: return x.kind == kind).size()
		check(n <= data.balance.shop.slots[kind], "%s: at most the slot count" % kind)
	for x: ShopState.Item in run.shop.items:
		check(x.price > 0, "%s %s has a price" % [x.kind, x.id])
		if x.kind == &"blueprint":
			check(not run.workshop.blueprints.has(x.id), "only unknown blueprints")
	check(not ShopRules.refresh(run, data, SeededRng.make_stream(4, &"shop", 1)), "once a week")
	run.day += data.balance.days_per_week
	check(ShopRules.refresh(run, data, SeededRng.make_stream(4, &"shop", 2)), "a new table on Monday")


func test_buying_never_goes_into_debt() -> void:
	var data := load_content(false)
	var run := _run(data)
	var x := _first(run, &"resource")
	run.money = x.price - 1
	check(ShopRules.buy(run, data, x.uid) != "", "too little money")
	run.money = x.price
	var before := run.workshop.amount(x.id)
	eq(ShopRules.buy(run, data, x.uid), "", "bought")
	eq(run.money, 0, "paid")
	eq(run.workshop.amount(x.id), before + x.amount, "the lot is in the stock")
	check(ShopRules.buy(run, data, x.uid) != "", "sold out")


func test_bag_fills_and_is_spent_in_fights() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.money = 999
	var x := _first(run, &"consumable")
	eq(ShopRules.buy(run, data, x.uid), "", "a consumable")
	eq(run.bag, [x.id] as Array[StringName], "into the bag")
	run.bag.append_array([x.id, x.id])
	var y := run.shop.items.filter(func(i: ShopState.Item) -> bool: return i.kind == &"consumable" and not i.sold)
	if not y.is_empty():
		check(ShopRules.buy(run, data, (y[0] as ShopState.Item).uid) != "", "the bag is full")
	var setup := DeckBuilder.default_setup(data, &"vigil_hound", 1)
	setup.deck.append_array(run.bag)
	var s := CombatRules.start(setup, data)
	var card := CardInstance.create(999, data.card(x.id))
	s.exhaust_pile.append(card)
	ShopRules.spend_bag(run, s)
	eq(run.bag.size(), 2, "one played card uses up one bag copy")


func test_selling_trophies_and_resources() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.workshop.trophies[&"fang"] = 2
	var money := run.money
	var paid := ShopRules.sell(run, data, &"fang")
	check(paid > 0, "a trophy has a price")
	eq(run.money, money + paid, "paid")
	eq(run.workshop.amount(&"fang"), 1, "one sold")
	var scrap := run.workshop.amount(&"scrap")
	eq(ShopRules.sell(run, data, &"scrap"), ShopRules.resource_sell_price(data, &"scrap"), "a unit of scrap")
	eq(run.workshop.amount(&"scrap"), scrap - 1, "scrap down")
	eq(ShopRules.sell(run, data, &"chitin"), 0, "nothing to sell")


func test_tavern_shift_pays_with_gossip() -> void:
	var data := load_content(false)
	var run := _run(data)
	var money := run.money
	var r := ShiftRules.work(run, data, SeededRng.make_stream(1, &"shift", 1))
	check(r.money >= data.balance.tavern.shift_money_min and r.money <= data.balance.tavern.shift_money_max, "pay in range")
	eq(run.money, money + r.money, "paid")
	check(r.gossip != &"", "a line of gossip")


func test_two_unpaid_rents_lock_the_workshop() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.money = -100
	var locked := false
	for i: int in data.balance.days_per_week * data.balance.debt_strikes:
		var report := DayRules.end_day(run, data)
		locked = locked or report.workshop_locked
	check(locked, "locked after %d unpaid rents" % data.balance.debt_strikes)
	if WorkshopRules.is_locked(run):
		check(WorkshopRules.craft(run, data, &"bayonet_mount") != "", "no crafting while locked")
	run.money = 10
	DayRules.end_day(run, data)
	eq(run.debt_strikes, 0, "money back at 0+ clears the count")


func test_shop_survives_save_and_old_saves_migrate() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.bag.append(&"bandage")
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.shop.to_dict(), run.shop.to_dict(), "table round trip")
	eq(back.bag, run.bag, "bag")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 6, "master_seed": 9}))
	eq(old.shop.items.size(), 0, "v6 save: no table yet")
	eq(old.bag.size(), 0, "empty bag")
