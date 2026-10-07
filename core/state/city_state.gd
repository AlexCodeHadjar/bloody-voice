class_name CityState
extends RefCounted
## States of districts, areas and landmarks. Keys: "NORDHAL", "NORDHAL/tavern_street", ...

var places: Dictionary[StringName, PlaceState] = {}


func get_place(key: StringName) -> PlaceState:
	if not places.has(key):
		places[key] = PlaceState.new()
	return places[key]


func state_of(key: StringName) -> StringName:
	return places[key].state if places.has(key) else &"normal"


func to_dict() -> Dictionary:
	var out := {}
	for key: StringName in places:
		out[key] = places[key].to_dict()
	return out


static func from_dict(d: Dictionary) -> CityState:
	var c := CityState.new()
	for key: Variant in d:
		c.places[StringName(str(key))] = PlaceState.from_dict(d[key] as Dictionary)
	return c
