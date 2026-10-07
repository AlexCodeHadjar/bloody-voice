class_name PlaceState
extends RefCounted
## Current state of a district / area / landmark (GDD 14). Pure data, serialisable.

var state: StringName = &"normal"
var days_left: int = 0  ## 0 = no timer
var next: StringName = &""  ## state after the timer ends ("" = back to previous)
var previous: StringName = &"normal"


func to_dict() -> Dictionary:
	return {"state": state, "days_left": days_left, "next": next, "previous": previous}


static func from_dict(d: Dictionary) -> PlaceState:
	var p := PlaceState.new()
	p.state = StringName(str(d.get("state", "normal")))
	p.days_left = int(d.get("days_left", 0))
	p.next = StringName(str(d.get("next", "")))
	p.previous = StringName(str(d.get("previous", "normal")))
	return p
