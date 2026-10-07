extends TestSuite


func test_weeks_and_weekdays() -> void:
	var b := load_content(false).balance
	eq(CalendarRules.week(1, b), 1, "day 1")
	eq(CalendarRules.week(7, b), 1, "day 7")
	eq(CalendarRules.week(8, b), 2, "day 8")
	eq(CalendarRules.weekday(1, b), 0, "day 1 is Monday")
	eq(CalendarRules.weekday_name(7, b), "Sunday", "day 7 name")


func test_rent_and_shop_days() -> void:
	var b := load_content(false).balance
	check(CalendarRules.is_rent_day(7, b), "Sunday is Rentday")
	check(not CalendarRules.is_rent_day(6, b), "Saturday is not")
	check(CalendarRules.is_shop_refresh_day(8, b), "Monday refresh")
	eq(CalendarRules.days_until_rent(1, b), 6, "Monday -> 6 days to rent")
	eq(CalendarRules.days_until_rent(7, b), 0, "rent today")


func test_chapter_week_wraps() -> void:
	var b := load_content(false).balance
	eq(CalendarRules.chapter_week(1, b), 1, "first week")
	eq(CalendarRules.chapter_week(29, b), 1, "week 5 = chapter week 1")
