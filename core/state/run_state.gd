class_name RunState
extends RefCounted
## Everything that is saved for one playthrough. Pure data: no nodes, no signals.
## Only GameState (through rules) changes it.

const SAVE_VERSION := 2

var master_seed: int = 0
var day: int = 1  ## day 1 = Monday of week 1
var money: int = 0
var hero_district: StringName = &""
var city: CityState = CityState.new()
var loadout: LoadoutState = LoadoutState.new()


static func create(seed_value: int, balance: BalanceDef) -> RunState:
	var r := RunState.new()
	r.master_seed = seed_value
	r.money = balance.start_money
	r.hero_district = balance.start_district
	r.loadout = LoadoutState.from_dict(balance.start_loadout)
	return r


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"master_seed": master_seed,
		"day": day,
		"money": money,
		"hero_district": hero_district,
		"city": city.to_dict(),
		"loadout": loadout.to_dict(),
	}


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	r.master_seed = int(d.get("master_seed", 0))
	r.day = int(d.get("day", 1))
	r.money = int(d.get("money", 0))
	r.hero_district = StringName(str(d.get("hero_district", "")))
	r.city = CityState.from_dict(d.get("city", {}) as Dictionary)
	r.loadout = LoadoutState.from_dict(d.get("loadout", {}) as Dictionary)
	return r
