class_name SkillsState
extends RefCounted
## Nodes the hunter bought in the skill webs (GDD 4.4): web id -> node ids (the start node is always owned and not
## stored). Saved. SkillRules changes it; screens only read it.

var owned: Dictionary[StringName, Array] = {}  ## web -> Array of node ids


func owned_in(web: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for v: Variant in owned.get(web, []) as Array:
		out.append(StringName(str(v)))
	return out


func to_dict() -> Dictionary:
	var out := {}
	for web: StringName in owned:
		out[web] = (owned[web] as Array).duplicate()
	return {"owned": out}


static func from_dict(d: Dictionary) -> SkillsState:
	var s := SkillsState.new()
	var src: Dictionary = d.get("owned", {})
	for web: Variant in src:
		s.owned[StringName(str(web))] = ContractsState.names(src[web] as Array)
	return s
