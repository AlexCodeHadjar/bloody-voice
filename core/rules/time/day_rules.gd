class_name DayRules
extends RefCounted
## Ending a day (GDD 3.2–3.3): advance the calendar, tick district states, take rent on Rentday.

class Report:
	var new_day: int
	var rent_taken: int = 0
	var state_changes: Array[DistrictStateRules.Change] = []


static func end_day(run: RunState, data: ContentData) -> Report:
	var report := Report.new()
	run.day += 1
	report.new_day = run.day
	report.state_changes = DistrictStateRules.tick(run.city, data.district_states)
	if CalendarRules.is_rent_day(run.day, data.balance):
		report.rent_taken = data.balance.weekly_rent
		run.money -= report.rent_taken  # may go negative: debt (GDD 3.2)
	return report
