class_name DayRules
extends RefCounted
## Ending a day (GDD 3.2–3.3): advance the calendar, tick district states, take rent on Rentday. Rent left unpaid
## (money below 0) debt_strikes times in a row shuts the workshop for that day; money back at 0+ clears the count.

class Report:
	var new_day: int
	var rent_taken: int = 0
	var workshop_locked: bool = false
	var state_changes: Array[DistrictStateRules.Change] = []


static func end_day(run: RunState, data: ContentData) -> Report:
	var report := Report.new()
	run.day += 1
	report.new_day = run.day
	report.state_changes = DistrictStateRules.tick(run.city, data.district_states)
	if run.money >= 0:
		run.debt_strikes = 0
	if CalendarRules.is_rent_day(run.day, data.balance):
		report.rent_taken = data.balance.weekly_rent
		run.money -= report.rent_taken  # may go negative: debt (GDD 3.2)
		if run.money < 0:
			run.debt_strikes += 1
			if run.debt_strikes >= data.balance.debt_strikes:
				run.workshop_locked_day = run.day
				report.workshop_locked = true
	return report
