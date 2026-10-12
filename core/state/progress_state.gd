class_name ProgressState
extends RefCounted
## The hunter's growth (GDD 4.1–4.3): level, XP toward the next level, free points, attributes. Saved.
## ProgressRules changes it; screens only read it.

var level: int = 1
var xp: int = 0  ## XP gathered toward the next level
var skill_points: int = 0  ## spent in the skill webs (Phase 6 step 2)
var attribute_points: int = 0
var attributes: Dictionary[StringName, int] = {}  ## will / agility / cunning
var started: bool = false  ## the start attributes were given (ProgressRules.ensure_start)


func attribute(id: StringName) -> int:
	return int(attributes.get(id, 0))


func to_dict() -> Dictionary:
	return {"level": level, "xp": xp, "skill_points": skill_points, "attribute_points": attribute_points,
		"attributes": attributes.duplicate(), "started": started}


static func from_dict(d: Dictionary) -> ProgressState:
	var s := ProgressState.new()
	s.level = int(d.get("level", 1))
	s.xp = int(d.get("xp", 0))
	s.skill_points = int(d.get("skill_points", 0))
	s.attribute_points = int(d.get("attribute_points", 0))
	s.attributes = WorkshopDefs.amounts(d.get("attributes", {}) as Dictionary)
	s.started = bool(d.get("started", false))
	return s
