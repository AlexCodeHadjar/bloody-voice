class_name CalendarRules
extends RefCounted
## Days, weeks and chapters (GDD 3.2). Day 1 is the Monday of week 1.

const WEEKDAY_NAMES: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


@warning_ignore("integer_division")
static func week(day: int, b: BalanceDef) -> int:
	return (day - 1) / b.days_per_week + 1


## 0 = Monday ... days_per_week - 1.
static func weekday(day: int, b: BalanceDef) -> int:
	return (day - 1) % b.days_per_week


static func weekday_name(day: int, b: BalanceDef) -> String:
	var i := weekday(day, b)
	return WEEKDAY_NAMES[i] if i < WEEKDAY_NAMES.size() else "Day %d" % (i + 1)


static func chapter_week(day: int, b: BalanceDef) -> int:
	return (week(day, b) - 1) % b.weeks_per_chapter + 1


static func is_rent_day(day: int, b: BalanceDef) -> bool:
	return weekday(day, b) == b.rent_weekday


static func is_shop_refresh_day(day: int, b: BalanceDef) -> bool:
	return weekday(day, b) == b.shop_refresh_weekday


static func days_until_rent(day: int, b: BalanceDef) -> int:
	return posmod(b.rent_weekday - weekday(day, b), b.days_per_week)
