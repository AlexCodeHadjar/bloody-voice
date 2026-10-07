class_name SaveMigrations
extends RefCounted
## Brings old save dictionaries up to RunState.SAVE_VERSION, one version step at a time.
## Add a `_from_N` function for every SAVE_VERSION bump; never rename ids that are in saves.


## start_loadout: the "gear" block of balance.json, used to give old saves the starting gear.
static func migrate(d: Dictionary, start_loadout: Dictionary = {}) -> Dictionary:
	var version := int(d.get("version", 1))
	while version < RunState.SAVE_VERSION:
		match version:
			1:
				_from_1(d, start_loadout)
			_:
				push_warning("[save] no migration from version %d" % version)
		version += 1
	d["version"] = RunState.SAVE_VERSION
	return d


## v1 -> v2: saves had no gear; give the starting loadout.
static func _from_1(d: Dictionary, start_loadout: Dictionary) -> void:
	if not d.has("loadout"):
		d["loadout"] = LoadoutState.from_dict(start_loadout).to_dict()
