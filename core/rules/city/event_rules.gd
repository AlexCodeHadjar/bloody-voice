class_name EventRules
extends RefCounted
## District events (GDD 15, owner 2026-10-12: random by weeks, the Grey Chapels only). Each Monday an event of the
## hero's district may start: it puts the district into its state for some days (DistrictStateRules), the state's
## numbers change prices, pay, rewards, rumors, creatures and shut places, and the morning leaflet tells the news.


## What the hero's district's state does now.
static func state_def(run: RunState, data: ContentData) -> DistrictStateDef:
	var def: DistrictStateDef = data.district_states.get(run.city.state_of(run.hero_district))
	return def if def != null else data.district_states.get(&"normal")


## The Monday roll (once a week). Returns the change when an event started, else null.
static func weekly(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> DistrictStateRules.Change:
	var b := data.balance.events
	var ev := run.events
	var week := CalendarRules.week(run.day, data.balance)
	if ev.checked_week == week:
		return null
	ev.checked_week = week
	if CalendarRules.weekday(run.day, data.balance) != 0 or ev.active != &"" or week < b.first_week:
		return null  # a save loaded mid-week waits for the next Monday
	if ev.ended_week > 0 and week <= ev.ended_week + b.rest_weeks:
		return null
	if rng.randf() >= b.chance:
		return null
	var weights: Dictionary[StringName, float] = {}
	for e: EventDefs.EventDef in data.events:
		if e.districts.has(run.hero_district):
			weights[e.id] = e.weight
	if weights.is_empty():
		return null
	return start(run, data, data.event(SeededRng.weighted(weights, rng)), rng)


## Starts `e` in the hero's district (also for tests and story steps).
static func start(run: RunState, data: ContentData, e: EventDefs.EventDef, rng: RandomNumberGenerator) -> DistrictStateRules.Change:
	var days := rng.randi_range(e.days_min, e.days_max)
	run.events.active = e.id
	run.events.news.append("%s:start" % e.id)
	return DistrictStateRules.apply(run.city, run.hero_district, e.state, days, data.district_states)


## After the day's state timers: the active event is over when the hero's district left its state.
static func after_tick(run: RunState, data: ContentData, changes: Array[DistrictStateRules.Change]) -> bool:
	var e := data.event(run.events.active)
	if e == null:
		return false
	for c: DistrictStateRules.Change in changes:
		if c.key == run.hero_district and c.new_state != e.state:
			run.events.news.append("%s:end" % e.id)
			run.events.active = &""
			run.events.ended_week = CalendarRules.week(run.day, data.balance)
			return true
	return false


## The oldest unread leaflet ("" = none) — the screen shows it, then calls read_news.
static func next_news(run: RunState) -> String:
	return run.events.news[0] if not run.events.news.is_empty() else ""


static func read_news(run: RunState) -> void:
	if not run.events.news.is_empty():
		run.events.news.remove_at(0)


static func is_closed(run: RunState, data: ContentData, action: StringName) -> bool:
	return state_def(run, data).closed_actions.has(action)


## A dangerous state makes the district's creatures stronger (per danger point).
static func strengthen(setup: CombatSetup, run: RunState, data: ContentData) -> void:
	var danger := state_def(run, data).danger_delta
	if danger <= 0:
		return
	setup.enemy_hp_mult *= pow(data.balance.events.danger_hp_mult, danger)
	setup.enemy_damage_bonus += data.balance.events.danger_damage * danger
