class_name SaveMigrations
extends RefCounted
## Brings old save dictionaries up to RunState.SAVE_VERSION, one version step at a time.
## Add a `_from_N` function for every SAVE_VERSION bump; never rename ids that are in saves.


## start_loadout: the "gear" block of balance.json, used to give old saves the starting gear.
static func migrate(d: Dictionary, start_loadout: Dictionary = {}) -> Dictionary:
	var version := int(d.get("version", 1))
	while version < RunState.SAVE_VERSION:
		_step(d, version, start_loadout)
		version += 1
	d["version"] = RunState.SAVE_VERSION
	return d


## One version step up from `version`.
static func _step(d: Dictionary, version: int, start_loadout: Dictionary) -> void:
	match version:
		1:
			_from_1(d, start_loadout)
		2:
			_from_2(d)
		3:
			_from_3(d)
		4:
			_from_4(d)
		5:
			_from_5(d)
		6:
			_from_6(d)
		7:
			_from_7(d)
		8:
			_from_8(d)
		9:
			_from_9(d)
		10:
			_from_10(d)
		11:
			_from_11(d)
		12:
			_from_12(d)
		13:
			_from_13(d)
		14:
			_from_14(d)
		15:
			_from_15(d)
		16:
			_from_16(d)
		17:
			_from_17(d)
		18:
			_from_18(d)
		_:
			push_warning("[save] no migration from version %d" % version)


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


## v4 -> v5: rumors (GDD 8). None yet; GameState adds the morning's rumors on load.
static func _from_4(d: Dictionary) -> void:
	d["rumors"] = RumorsState.new().to_dict()


## v5 -> v6: workshop stock (GDD 6). Empty here; GameState gives the start stock and blueprints on load
## (WorkshopRules.ensure_start, `started` is false).
static func _from_5(d: Dictionary) -> void:
	d["workshop"] = WorkshopState.new().to_dict()


## v6 -> v7: the shop, the bag and rent debt (GDD 11.1, 3.2). An empty table is stocked on load.
static func _from_6(d: Dictionary) -> void:
	d["shop"] = ShopState.new().to_dict()
	d["bag"] = []
	d["debt_strikes"] = 0
	d["workshop_locked_day"] = 0


## v7 -> v8: HP and Sanity between fights (GDD 4). Old saves start full.
static func _from_7(d: Dictionary) -> void:
	d["hero_hp"] = -1
	d["hero_sanity"] = -1


## v8 -> v9: module tiers move from the module kind to each copy (owner, 2026-10-12): every owned copy and every
## placement gets the tier its kind had.
static func _from_8(d: Dictionary) -> void:
	var l: Dictionary = d.get("loadout", {})
	var kind_tiers: Dictionary = l.get("module_tiers", {})
	var tiers: Array = []
	for m: Variant in l.get("owned_modules", []) as Array:
		tiers.append(int(kind_tiers.get(str(m), 1)))
	l["owned_tiers"] = tiers
	for p: Variant in l.get("placements", []) as Array:
		(p as Dictionary)["tier"] = int(kind_tiers.get(str((p as Dictionary).get("module", "")), 1))
	l.erase("module_tiers")


## v9 -> v10: levels and attributes (GDD 4). Level 1, no XP; GameState gives the start attributes on load.
static func _from_9(d: Dictionary) -> void:
	d["progress"] = ProgressState.new().to_dict()


## v10 -> v11: skill webs (GDD 4.4). Nothing bought yet; the points earned so far wait in progress.skill_points.
static func _from_10(d: Dictionary) -> void:
	d["skills"] = SkillsState.new().to_dict()


## v11 -> v12: the Voice and blood samples (GDD 4.2, 4.4). Silent at first, no samples yet.
static func _from_11(d: Dictionary) -> void:
	d["voice"] = 0
	var ws: Dictionary = d.get("workshop", {})
	ws["samples"] = {}
	ws["pure_samples"] = {}


## v12 -> v13: the Bestiary, reputation and the Register rank (GDD 10.3, 12). Old runs start at rank A, neutral,
## knowing nothing.
static func _from_12(d: Dictionary) -> void:
	d["bestiary"] = {"marks": {}}
	d["standing"] = {"reputation": {}, "rank": 0, "rank_contracts": 0, "exam_block_week": 0}


## v13 -> v14: district events (GDD 15). No event yet; the first roll comes on the next Monday.
static func _from_13(d: Dictionary) -> void:
	d["events"] = {"checked_week": 0, "active": "", "ended_week": 0, "news": []}


## v14 -> v15: creature affixes on contracts (GDD 17). Old contracts have none.
static func _from_14(d: Dictionary) -> void:
	for c: Variant in (d.get("contracts", {}) as Dictionary).get("items", []) as Array:
		(c as Dictionary)["affixes"] = []


## v15 -> v16: the district story (GDD 2.4). Not started yet: the prologue's letter comes on load.
static func _from_15(d: Dictionary) -> void:
	d["story"] = {"started": false, "done": [], "choice": "", "finished": false, "letters": []}


## v16 -> v17: blood cells in the loadout (GDD 4.8). Empty here; GameState re-syncs them from the owned nodes on load.
static func _from_16(d: Dictionary) -> void:
	var l: Dictionary = d.get("loadout", {})
	l["blood_cells"] = {}


## v17 -> v18: listening for rumors (GDD 8.4, owner 2026-10-14). The old morning diamonds are dropped; trails, threat
## counts and marks start empty.
static func _from_17(d: Dictionary) -> void:
	d["rumors"] = {}


## v18 -> v19: the notebook of rumor cards (GDD 8.4, owner 2026-10-15). Listening trails, threat counts and marks are
## dropped; the notebook starts empty.
static func _from_18(d: Dictionary) -> void:
	d["rumors"] = {}
