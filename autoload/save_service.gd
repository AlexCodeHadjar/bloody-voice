extends Node
## Save / load of RunState as JSON, with versioned migrations (GDD 19.1).

const SLOT_PATH := "user://save_slot_1.json"


func has_save(path: String = SLOT_PATH) -> bool:
	return FileAccess.file_exists(path)


func save_run(run: RunState, path: String = SLOT_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("[save] cannot write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(JSON.stringify(run.to_dict(), "\t"))
	return true


func load_run(path: String = SLOT_PATH) -> RunState:
	if not has_save(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[save] broken save file %s" % path)
		return null
	return RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
