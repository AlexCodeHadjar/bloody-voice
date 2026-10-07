class_name SaveMigrations
extends RefCounted
## Brings old save dictionaries up to RunState.SAVE_VERSION, one version step at a time.
## Add a `_from_N` function for every SAVE_VERSION bump; never rename ids that are in saves.


static func migrate(d: Dictionary) -> Dictionary:
	var version := int(d.get("version", 1))
	while version < RunState.SAVE_VERSION:
		match version:
			_:
				push_warning("[save] no migration from version %d" % version)
		version += 1
	d["version"] = RunState.SAVE_VERSION
	return d
