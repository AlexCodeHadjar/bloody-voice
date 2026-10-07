extends TestSuite


func test_timed_state_returns_to_previous() -> void:
	var states := load_content(false).district_states
	var city := CityState.new()
	DistrictStateRules.apply(city, &"NORDHAL", &"riot", 2, states)
	eq(city.state_of(&"NORDHAL"), &"riot", "riot started")
	eq(DistrictStateRules.tick(city, states).size(), 0, "day 1: still riot")
	var changes := DistrictStateRules.tick(city, states)
	eq(changes.size(), 1, "day 2: change")
	eq(city.state_of(&"NORDHAL"), &"normal", "back to normal")


func test_chain_goes_to_next_state() -> void:
	var states := load_content(false).district_states
	var city := CityState.new()
	DistrictStateRules.apply(city, &"MARKET", &"burning", 1, states)
	DistrictStateRules.tick(city, states)
	eq(city.state_of(&"MARKET"), &"burned", "burning -> burned")
	eq(city.get_place(&"MARKET").days_left, 0, "burned has no timer")


func test_untimed_state_stays() -> void:
	var states := load_content(false).district_states
	var city := CityState.new()
	DistrictStateRules.apply(city, &"DEEPWRIGHT/shaft_7", &"collapsed", 0, states)
	for i: int in 5:
		DistrictStateRules.tick(city, states)
	eq(city.state_of(&"DEEPWRIGHT/shaft_7"), &"collapsed", "permanent scar")


func test_unknown_place_is_normal() -> void:
	eq(CityState.new().state_of(&"GREY"), &"normal", "default state")
