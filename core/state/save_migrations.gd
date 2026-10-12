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
			2:
				_from_2(d)
			3:
				_from_3(d)
			_:
				push_warning("[save] no migration from version %d" % version)
		version += 1
	d["version"] = RunState.SAVE_VERSION
	return d


## v1 -> v2: saves had no gear; give the starting loadout.
static func _from_1(d: Dictionary, start_loadout: Dictionary) -> void:
	if not d.has("loadout"):
		d["loadout"] = LoadoutState.from_dict(start_loadout).to_dict()


## v2 -> v3: the game starts confined to GREY; saves get hero_node and open_districts.
static func _from_2(d: Dictionary) -> void:
	d["hero_node"] = ""
	d["open_districts"] = ["GREY"]
	if str(d.get("hero_district", "")) != "GREY":
		d["hero_district"] = "GREY"


## v3 -> v4: contracts (GDD 7). An empty board; GameState fills it for the current week on load.
static func _from_3(d: Dictionary) -> void:
	d["contracts"] = ContractsState.new().to_dict()
