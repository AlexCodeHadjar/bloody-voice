class_name EventsState
extends RefCounted
## District events (GDD 15): the week last rolled, the event on now and when the last one ended, and the news
## leaflets the hunter has not read yet. Saved. EventRules changes it; screens only read it.

var checked_week: int = 0  ## the Monday roll is done for this week
var active: StringName = &""  ## the event on now ("" = none)
var ended_week: int = 0  ## the week the last event ended (rest_weeks count from it)
var news: Array[String] = []  ## unread leaflets: "<event>:start" / "<event>:end"


func to_dict() -> Dictionary:
	return {"checked_week": checked_week, "active": active, "ended_week": ended_week, "news": news.duplicate()}


static func from_dict(d: Dictionary) -> EventsState:
	var s := EventsState.new()
	s.checked_week = int(d.get("checked_week", 0))
	s.active = StringName(str(d.get("active", "")))
	s.ended_week = int(d.get("ended_week", 0))
	for v: Variant in d.get("news", []) as Array:
		s.news.append(str(v))
	return s
