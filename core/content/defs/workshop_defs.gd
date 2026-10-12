class_name WorkshopDefs
extends RefCounted
## Workshop content (GDD 6, 23.1): blueprints (data/gear/blueprints.json) and the "workshop" block of balance.json
## (resources, start stock, crafts per day, salvage share, loot by rank).

const KINDS: Array[StringName] = [&"module", &"mechanism"]


class BlueprintDef:
	var item: StringName  ## module or mechanism id
	var kind: StringName  ## module / mechanism
	var start: bool = false  ## known from the beginning
	var unlock: StringName = &""  ## trophy whose first find teaches it
	var cost: Dictionary[StringName, int] = {}  ## resource or trophy id -> amount
	var upgrade: Array[Dictionary] = []  ## costs of tiers II and III (modules), same shape as `cost`


class Balance:
	var resources: Array[StringName] = []
	var start_resources: Dictionary[StringName, int] = {}
	var crafts_per_day: int = 2
	var salvage_share: float = 0.5
	var loot_by_rank: Dictionary[String, Dictionary] = {}  ## rank -> {resource: amount}
	var capture_ichor_mult: int = 1


static func blueprint(d: Dictionary, errs: ErrorLog) -> BlueprintDef:
	var b := BlueprintDef.new()
	b.item = DefReader.id(d, "item", errs, "gear/blueprints.json")
	var w := "gear/blueprints.json/%s" % b.item
	b.kind = DefReader.id(d, "kind", errs, w)
	b.start = DefReader.flag(d, "start")
	b.unlock = DefReader.id(d, "unlock", errs, w, false)
	b.cost = amounts(DefReader.dict(d, "cost", errs, w))
	for u: Variant in DefReader.array(d, "upgrade", errs, w, false):
		b.upgrade.append(amounts(u as Dictionary))
	return b


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/workshop"
	b.resources = DefReader.ids(d, "resources", errs, w)
	b.start_resources = amounts(DefReader.dict(d, "start_resources", errs, w))
	b.crafts_per_day = DefReader.integer(d, "crafts_per_day", errs, w, 2)
	b.salvage_share = DefReader.number(d, "salvage_share", errs, w, 0.5)
	var loot := DefReader.dict(d, "loot_by_rank", errs, w)
	for rank: Variant in loot:
		b.loot_by_rank[str(rank)] = amounts(loot[rank] as Dictionary)
	b.capture_ichor_mult = DefReader.integer(d, "capture_ichor_mult", errs, w, 1)
	return b


## {"scrap": 3} -> typed {&"scrap": 3}.
static func amounts(d: Dictionary) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	for k: Variant in d:
		out[StringName(str(k))] = int(d[k])
	return out
