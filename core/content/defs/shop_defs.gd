class_name ShopDefs
extends RefCounted
## The "shop" and "tavern" blocks of balance.json (GDD 11.1, 3.3): stock slots, prices, trophy prices, the bag,
## the tavern shift.

const KINDS: Array[StringName] = [&"module", &"blueprint", &"consumable", &"resource"]


class Balance:
	var slots: Dictionary[StringName, int] = {}  ## kind -> how many on the table
	var resource_prices: Dictionary[StringName, int] = {}
	var module_mult: float = 1.5
	var mechanism_mult: float = 1.5
	var blueprint_mult: float = 2.0
	var price_step: int = 5
	var consumables: Dictionary[StringName, int] = {}  ## card id -> price
	var lots: Dictionary[StringName, Vector2i] = {}  ## resource -> [min, max] amount of a lot
	var trophy_price_by_rank: Dictionary[String, int] = {}
	var sell_share: float = 0.5
	var bag_size: int = 3


class Tavern:
	var shift_money_min: int = 0
	var shift_money_max: int = 0
	var overheard_true_chance: float = 0.0


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/shop"
	b.slots = WorkshopDefs.amounts(DefReader.dict(d, "slots", errs, w))
	b.resource_prices = WorkshopDefs.amounts(DefReader.dict(d, "resource_prices", errs, w))
	b.module_mult = DefReader.number(d, "module_mult", errs, w, 1.5)
	b.mechanism_mult = DefReader.number(d, "mechanism_mult", errs, w, 1.5)
	b.blueprint_mult = DefReader.number(d, "blueprint_mult", errs, w, 2.0)
	b.price_step = DefReader.integer(d, "price_step", errs, w, 5)
	b.consumables = WorkshopDefs.amounts(DefReader.dict(d, "consumables", errs, w))
	var lots := DefReader.dict(d, "lots", errs, w)
	for k: Variant in lots:
		var a: Array = lots[k] if typeof(lots[k]) == TYPE_ARRAY else []
		if a.size() != 2:
			errs.add(w, "lots/%s must be [min, max]" % k)
			continue
		b.lots[StringName(str(k))] = Vector2i(int(a[0]), int(a[1]))
	var trophies := DefReader.dict(d, "trophy_price_by_rank", errs, w)
	for rank: Variant in trophies:
		b.trophy_price_by_rank[str(rank)] = int(trophies[rank])
	b.sell_share = DefReader.number(d, "sell_share", errs, w, 0.5)
	b.bag_size = DefReader.integer(d, "bag_size", errs, w, 3)
	return b


static func tavern(d: Dictionary, errs: ErrorLog) -> Tavern:
	var t := Tavern.new()
	var w := "balance.json/tavern"
	t.shift_money_min = DefReader.integer(d, "shift_money_min", errs, w)
	t.shift_money_max = DefReader.integer(d, "shift_money_max", errs, w)
	t.overheard_true_chance = DefReader.number(d, "overheard_true_chance", errs, w)
	return t
