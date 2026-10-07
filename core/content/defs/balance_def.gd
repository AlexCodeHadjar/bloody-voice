class_name BalanceDef
extends RefCounted
## All tuning numbers from data/balance.json. Code reads them from here, never hard-codes them.

var days_per_week: int = 7
var weeks_per_chapter: int = 4
var rent_weekday: int = 6
var shop_refresh_weekday: int = 0

var start_money: int = 0
var weekly_rent: int = 0

var start_district: StringName = &""
var base_hp: int = 0
var hp_per_level: int = 0
var base_ap: int = 0
var hand_size: int = 0

var capture_per_cunning: float = 0.0
var capture_per_broken_part: float = 0.0
var capture_max_chance: float = 0.0


static func from_dict(d: Dictionary, errs: ErrorLog) -> BalanceDef:
	var b := BalanceDef.new()
	var w := "balance.json"
	var cal := DefReader.dict(d, "calendar", errs, w)
	b.days_per_week = DefReader.integer(cal, "days_per_week", errs, w + "/calendar", 7)
	b.weeks_per_chapter = DefReader.integer(cal, "weeks_per_chapter", errs, w + "/calendar", 4)
	b.rent_weekday = DefReader.integer(cal, "rent_weekday", errs, w + "/calendar", 6)
	b.shop_refresh_weekday = DefReader.integer(cal, "shop_refresh_weekday", errs, w + "/calendar", 0)
	var eco := DefReader.dict(d, "economy", errs, w)
	b.start_money = DefReader.integer(eco, "start_money", errs, w + "/economy")
	b.weekly_rent = DefReader.integer(eco, "weekly_rent", errs, w + "/economy")
	var hero := DefReader.dict(d, "hero", errs, w)
	b.start_district = DefReader.id(hero, "start_district", errs, w + "/hero")
	b.base_hp = DefReader.integer(hero, "base_hp", errs, w + "/hero")
	b.hp_per_level = DefReader.integer(hero, "hp_per_level", errs, w + "/hero")
	b.base_ap = DefReader.integer(hero, "base_ap", errs, w + "/hero")
	b.hand_size = DefReader.integer(hero, "hand_size", errs, w + "/hero")
	var cap := DefReader.dict(d, "capture", errs, w)
	b.capture_per_cunning = DefReader.number(cap, "per_cunning", errs, w + "/capture")
	b.capture_per_broken_part = DefReader.number(cap, "per_broken_part", errs, w + "/capture")
	b.capture_max_chance = DefReader.number(cap, "max_chance", errs, w + "/capture")
	return b
