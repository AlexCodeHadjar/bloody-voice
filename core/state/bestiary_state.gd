class_name BestiaryState
extends RefCounted
## What the hunter knows of each creature (GDD 10.3): creature -> knowledge marks (StandingDefs.KNOWLEDGE). Saved.
## BestiaryRules changes it; screens only read it.

var marks: Dictionary[StringName, Array] = {}  ## creature -> Array of marks


func of(creature: StringName) -> Array[StringName]:
	return ContractsState.names(marks.get(creature, []) as Array)


func has(creature: StringName, mark: StringName) -> bool:
	return of(creature).has(mark)


func to_dict() -> Dictionary:
	var out := {}
	for c: StringName in marks:
		out[c] = (marks[c] as Array).duplicate()
	return {"marks": out}


static func from_dict(d: Dictionary) -> BestiaryState:
	var s := BestiaryState.new()
	var src: Dictionary = d.get("marks", {})
	for c: Variant in src:
		s.marks[StringName(str(c))] = ContractsState.names(src[c] as Array)
	return s
