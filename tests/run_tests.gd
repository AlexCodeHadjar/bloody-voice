extends SceneTree
## Headless test runner:
##   Godot --headless --path . -s res://tests/run_tests.gd [-- --only=name]
## Exit code 0 = all green.

const SUITES: Array[String] = [
	"res://tests/test_scripts.gd",
	"res://tests/test_content.gd",
	"res://tests/test_calendar.gd",
	"res://tests/test_day_rules.gd",
	"res://tests/test_district_states.gd",
	"res://tests/test_rng.gd",
	"res://tests/test_save.gd",
	"res://tests/test_map_regions.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_gear.gd",
]


func _initialize() -> void:
	var only := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	var total := 0
	var failed: PackedStringArray = []
	for path: String in SUITES:
		if only != "" and not path.contains(only):
			continue
		var script := load(path) as GDScript
		if script == null:
			failed.append("%s: cannot load suite" % path)
			continue
		var suite := script.new() as TestSuite
		for m: Dictionary in script.get_script_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			total += 1
			suite.current_test = "%s.%s" % [path.get_file().get_basename(), method]
			suite.call(method)
		failed.append_array(suite.failures)
	for f: String in failed:
		printerr("FAIL ", f)
	print("%d tests, %d failures" % [total, failed.size()])
	quit(1 if not failed.is_empty() else 0)
