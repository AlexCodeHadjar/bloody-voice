class_name RunState
extends RefCounted
## Everything that is saved for one playthrough. Pure data: no nodes, no signals.
## Only GameState (through rules) changes it.

const SAVE_VERSION := 8

var master_seed: int = 0
var day: int = 1  ## day 1 = Monday of week 1
var money: int = 0
var hero_district: StringName = &""
var hero_node: StringName = &""  ## where the hero stands on the district map; "" = the map's home node
var open_districts: Array[StringName] = []  ## districts the hero may enter; the rest are locked
var city: CityState = CityState.new()
var loadout: LoadoutState = LoadoutState.new()
var contracts: ContractsState = ContractsState.new()  ## tavern board and accepted contracts (GDD 7)
var rumors: RumorsState = RumorsState.new()  ## rumor diamonds on the district map (GDD 8)
var shop: ShopState = ShopState.new()  ## the Rag-and-Bone table this week (GDD 11.1)
var bag: Array[StringName] = []  ## consumable cards carried into every fight until played (shop.bag_size)
var debt_strikes: int = 0  ## rents in a row left unpaid (GDD 3.2)
var hero_hp: int = -1  ## HP carried between fights; -1 = full (GDD 4)
var hero_sanity: int = -1  ## Sanity carried between fights; -1 = full
var workshop_locked_day: int = 0  ## the workshop is shut for debt on this day
var workshop: WorkshopState = WorkshopState.new()  ## resources, trophies, blueprints (GDD 6); filled by WorkshopRules.ensure_start


static func create(seed_value: int, balance: BalanceDef) -> RunState:
	var r := RunState.new()
	r.master_seed = seed_value
	r.money = balance.start_money
	r.hero_district = balance.start_district
	r.open_districts = balance.open_districts.duplicate()
	r.loadout = LoadoutState.from_dict(balance.start_loadout)
	return r


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"master_seed": master_seed,
		"day": day,
		"money": money,
		"hero_district": hero_district,
		"hero_node": hero_node,
		"open_districts": open_districts,
		"city": city.to_dict(),
		"loadout": loadout.to_dict(),
		"contracts": contracts.to_dict(),
		"rumors": rumors.to_dict(),
		"workshop": workshop.to_dict(),
		"shop": shop.to_dict(),
		"bag": bag,
		"debt_strikes": debt_strikes,
		"hero_hp": hero_hp,
		"hero_sanity": hero_sanity,
		"workshop_locked_day": workshop_locked_day,
	}


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	r.master_seed = int(d.get("master_seed", 0))
	r.day = int(d.get("day", 1))
	r.money = int(d.get("money", 0))
	r.hero_district = StringName(str(d.get("hero_district", "")))
	r.hero_node = StringName(str(d.get("hero_node", "")))
	for v: Variant in d.get("open_districts", []) as Array:
		r.open_districts.append(StringName(str(v)))
	r.city = CityState.from_dict(d.get("city", {}) as Dictionary)
	r.loadout = LoadoutState.from_dict(d.get("loadout", {}) as Dictionary)
	r.contracts = ContractsState.from_dict(d.get("contracts", {}) as Dictionary)
	r.rumors = RumorsState.from_dict(d.get("rumors", {}) as Dictionary)
	r.workshop = WorkshopState.from_dict(d.get("workshop", {}) as Dictionary)
	r.shop = ShopState.from_dict(d.get("shop", {}) as Dictionary)
	r.bag = ContractsState.names(d.get("bag", []) as Array)
	r.debt_strikes = int(d.get("debt_strikes", 0))
	r.hero_hp = int(d.get("hero_hp", -1))
	r.hero_sanity = int(d.get("hero_sanity", -1))
	r.workshop_locked_day = int(d.get("workshop_locked_day", 0))
	return r
