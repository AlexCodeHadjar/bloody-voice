class_name DistrictStateRules
extends RefCounted
## Changing and ticking district / area / landmark states (GDD 14.3).
## Rules mutate the state object they are given and return what changed; they never emit signals.

class Change:
	var key: StringName
	var old_state: StringName
	var new_state: StringName


## Put a place into a state. days = 0 means "until changed again".
static func apply(city: CityState, key: StringName, new_state: StringName, days: int,
		states: Dictionary[StringName, DistrictStateDef]) -> Change:
	var place := city.get_place(key)
	var change := _change(key, place.state, new_state)
	var def: DistrictStateDef = states.get(new_state)
	place.previous = place.state
	place.state = new_state
	place.days_left = maxi(0, days)
	place.next = def.next if def != null else &""
	return change


## Advance all timers by one day. Returns the places whose state changed.
static func tick(city: CityState, states: Dictionary[StringName, DistrictStateDef]) -> Array[Change]:
	var changes: Array[Change] = []
	for key: StringName in city.places:
		var place: PlaceState = city.places[key]
		if place.days_left <= 0:
			continue
		place.days_left -= 1
		if place.days_left > 0:
			continue
		var target := place.next if place.next != &"" else place.previous
		changes.append(apply(city, key, target, 0, states))
	return changes


static func _change(key: StringName, old_state: StringName, new_state: StringName) -> Change:
	var c := Change.new()
	c.key = key
	c.old_state = old_state
	c.new_state = new_state
	return c
