extends TestSuite


func test_rent_is_taken_on_rentday() -> void:
	var data := load_content(false)
	var run := RunState.create(1, data.balance)
	run.day = 6
	var start := run.money
	var report := DayRules.end_day(run, data)
	eq(run.day, 7, "day advanced")
	eq(report.rent_taken, data.balance.weekly_rent, "rent reported")
	eq(run.money, start - data.balance.weekly_rent, "money reduced")


func test_no_rent_on_other_days() -> void:
	var data := load_content(false)
	var run := RunState.create(1, data.balance)
	var start := run.money
	DayRules.end_day(run, data)
	eq(run.money, start, "no rent on Tuesday")


func test_day_ticks_district_states() -> void:
	var data := load_content(false)
	var run := RunState.create(1, data.balance)
	DistrictStateRules.apply(run.city, &"AVENUES", &"flooded", 1, data.district_states)
	var report := DayRules.end_day(run, data)
	eq(report.state_changes.size(), 1, "one change")
	eq(run.city.state_of(&"AVENUES"), &"normal", "flood is over")
