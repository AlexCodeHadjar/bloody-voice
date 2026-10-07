extends TestSuite

const SaveServiceScript := preload("res://autoload/save_service.gd")
const PATH := "user://test_save_slot.json"


func test_round_trip_through_json() -> void:
	var data := load_content(false)
	var run := RunState.create(777, data.balance)
	run.day = 12
	run.money = -5
	run.hero_district = &"GREY"
	DistrictStateRules.apply(run.city, &"AVENUES", &"flooded", 3, data.district_states)
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.master_seed, 777, "seed")
	eq(back.day, 12, "day")
	eq(back.money, -5, "money")
	eq(back.hero_district, &"GREY", "hero district")
	eq(back.city.state_of(&"AVENUES"), &"flooded", "district state")
	eq(back.city.get_place(&"AVENUES").days_left, 3, "timer")


func test_save_service_file() -> void:
	var data := load_content(false)
	var service: Node = SaveServiceScript.new()
	var run := RunState.create(5, data.balance)
	check(service.call("save_run", run, PATH) as bool, "saved")
	var back := service.call("load_run", PATH) as RunState
	check(back != null and back.master_seed == 5, "loaded")
	service.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
