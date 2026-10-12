extends TestSuite
## Save / load round trip and save migrations (GDD 19.1).

const SaveServiceScript := preload("res://autoload/save_service.gd")
const PATH := "user://test_save_slot.json"


func test_round_trip_through_json() -> void:
	var data := load_content(false)
	var run := RunState.create(777, data.balance)
	run.day = 12
	run.money = -5
	run.hero_district = &"GREY"
	run.hero_node = &"gate"
	run.open_districts.append(&"AVENUES")
	DistrictStateRules.apply(run.city, &"AVENUES", &"flooded", 3, data.district_states)
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.master_seed, 777, "seed")
	eq(back.day, 12, "day")
	eq(back.money, -5, "money")
	eq(back.hero_district, &"GREY", "hero district")
	eq(back.hero_node, &"gate", "hero node")
	eq(back.open_districts, [&"GREY", &"AVENUES"] as Array[StringName], "open districts")
	eq(back.city.state_of(&"AVENUES"), &"flooded", "district state")
	eq(back.city.get_place(&"AVENUES").days_left, 3, "timer")


func test_new_run_starts_in_grey_only() -> void:
	var data := load_content(false)
	var run := RunState.create(1, data.balance)
	eq(run.hero_district, &"GREY", "start district")
	eq(run.open_districts, [&"GREY"] as Array[StringName], "open at start")
	eq(run.hero_node, &"", "home node")


func test_migrate_v2_to_v3() -> void:
	var old := {"version": 2, "master_seed": 9, "hero_district": "NORDHAL"}
	var back := RunState.from_dict(SaveMigrations.migrate(old))
	eq(back.hero_district, &"GREY", "moved to GREY")
	eq(back.hero_node, &"", "hero node added")
	eq(back.open_districts, [&"GREY"] as Array[StringName], "open added")
	eq(back.master_seed, 9, "rest kept")


func test_save_service_file() -> void:
	var data := load_content(false)
	var service: Node = SaveServiceScript.new()
	var run := RunState.create(5, data.balance)
	check(service.call("save_run", run, PATH) as bool, "saved")
	var back := service.call("load_run", PATH) as RunState
	check(back != null and back.master_seed == 5, "loaded")
	service.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
