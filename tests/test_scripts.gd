extends TestSuite
## Every script in the project must compile.

const ROOTS: Array[String] = ["res://autoload", "res://core", "res://scenes", "res://ui", "res://tests"]


func test_all_scripts_compile() -> void:
	var count := 0
	for root: String in ROOTS:
		for path: String in _scripts(root):
			count += 1
			var s := load(path) as GDScript
			check(s != null and s.can_instantiate(), "does not compile: %s" % path)
	check(count > 10, "found only %d scripts" % count)


func _scripts(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f: String in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for sub: String in dir.get_directories():
		out.append_array(_scripts(dir_path.path_join(sub)))
	return out
