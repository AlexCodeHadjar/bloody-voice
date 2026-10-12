class_name EventDefs
extends RefCounted
## District events (GDD 15): data/city/events.json and the "events" block of balance.json.


class EventDef:
	var id: StringName
	var state: StringName  ## the district state it brings (district_states.json)
	var districts: Array[StringName] = []
	var weight: float = 1.0
	var days_min: int = 1
	var days_max: int = 1
	var name: String
	var news: String  ## the morning leaflet when it starts
	var end_news: String  ## ... and when it is over


class Balance:
	var first_week: int = 2
	var chance: float = 0.0
	var rest_weeks: int = 1
	var danger_hp_mult: float = 1.0
	var danger_damage: int = 0


static func event(d: Dictionary, errs: ErrorLog) -> EventDef:
	var e := EventDef.new()
	e.id = DefReader.id(d, "id", errs, "city/events.json")
	var w := "city/events.json/%s" % e.id
	e.state = DefReader.id(d, "state", errs, w)
	e.districts = DefReader.ids(d, "districts", errs, w)
	e.weight = DefReader.number(d, "weight", errs, w, 1.0)
	var days := ProgressDefs.ints(DefReader.array(d, "days", errs, w))
	if days.size() != 2 or days[0] < 1 or days[1] < days[0]:
		errs.add(w, "days must be [min, max] with 1 <= min <= max")
	else:
		e.days_min = days[0]
		e.days_max = days[1]
	e.name = DefReader.string(d, "name", errs, w)
	e.news = DefReader.string(d, "news", errs, w)
	e.end_news = DefReader.string(d, "end_news", errs, w)
	return e


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/events"
	b.first_week = DefReader.integer(d, "first_week", errs, w, 2)
	b.chance = DefReader.number(d, "chance", errs, w)
	b.rest_weeks = DefReader.integer(d, "rest_weeks", errs, w, 1)
	b.danger_hp_mult = DefReader.number(d, "danger_hp_mult", errs, w, 1.0)
	b.danger_damage = DefReader.integer(d, "danger_damage", errs, w)
	return b
