class_name WorkshopState
extends RefCounted
## The hunter's stock and workshop (GDD 6): resources, trophies, known blueprints and today's workshop day.
## Saved. WorkshopRules and LootRules change it; screens only read it.

var resources: Dictionary[StringName, int] = {}  ## scrap / gears / electronics / ichor -> amount
var trophies: Dictionary[StringName, int] = {}  ## trophy id -> amount
var blueprints: Array[StringName] = []  ## known blueprint (item) ids
var day: int = 0  ## the day a workshop day was started (0 = none)
var crafts_used: int = 0  ## crafts and upgrades done on that day


## A resource or trophy id -> how many the hunter has.
func amount(id: StringName) -> int:
	return int(resources.get(id, trophies.get(id, 0)))


func to_dict() -> Dictionary:
	return {"resources": resources.duplicate(), "trophies": trophies.duplicate(), "blueprints": blueprints.duplicate(),
		"day": day, "crafts_used": crafts_used}


static func from_dict(d: Dictionary) -> WorkshopState:
	var s := WorkshopState.new()
	s.resources = WorkshopDefs.amounts(d.get("resources", {}) as Dictionary)
	s.trophies = WorkshopDefs.amounts(d.get("trophies", {}) as Dictionary)
	s.blueprints = ContractsState.names(d.get("blueprints", []) as Array)
	s.day = int(d.get("day", 0))
	s.crafts_used = int(d.get("crafts_used", 0))
	return s


## A new run: the start stock and the start blueprints.
static func create(data: ContentData) -> WorkshopState:
	var s := WorkshopState.new()
	s.resources = data.balance.workshop.start_resources.duplicate()
	for id: StringName in data.blueprint_order:
		if data.blueprint(id).start:
			s.blueprints.append(id)
	return s
