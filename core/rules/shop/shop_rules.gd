class_name ShopRules
extends RefCounted
## The Rag-and-Bone shop (GDD 11.1, owner 2026-10-12): a new table every Monday, buying (only with money in hand —
## never into debt), selling trophies and resources, the bag of consumables that go into every fight until played.


## Stocks the table for the week of run.day unless it already is. Returns true when it changed.
static func refresh(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> bool:
	var week := CalendarRules.week(run.day, data.balance)
	if run.shop.week == week:
		return false
	run.shop.items = ShopGenerator.generate(data, run, rng, run.shop.next_uid)
	run.shop.next_uid += run.shop.items.size()
	run.shop.week = week
	return true


## "" or why the item can't be bought now (shown to the player).
static func can_buy(run: RunState, data: ContentData, uid: int) -> String:
	var x := run.shop.find(uid)
	if x == null or x.sold:
		return Loc.t("rule.shop.sold")
	if run.money < x.price:
		return Loc.t("rule.shop.no_money")
	if x.kind == &"consumable" and run.bag.size() >= data.balance.shop.bag_size:
		return Loc.t("rule.shop.bag_full", {"n": data.balance.shop.bag_size})
	if x.kind == &"blueprint" and run.workshop.blueprints.has(x.id):
		return Loc.t("rule.shop.known")
	return ""


static func buy(run: RunState, data: ContentData, uid: int) -> String:
	var problem := can_buy(run, data, uid)
	if problem != "":
		return problem
	var x := run.shop.find(uid)
	run.money -= x.price
	x.sold = true
	match x.kind:
		&"module":
			run.loadout.add_module(x.id)
		&"blueprint":
			run.workshop.blueprints.append(x.id)
		&"consumable":
			run.bag.append(x.id)
		&"resource":
			LootRules.add_resources(run.workshop, {x.id: x.amount})
	return ""


## What one trophy fetches: by the rank of the first creature that drops it.
static func trophy_price(data: ContentData, trophy: StringName) -> int:
	for id: StringName in data.monster_order:
		var m := data.monster(id)
		for p: MonsterDef.PartDef in m.parts:
			if p.trophy == trophy:
				return int(data.balance.shop.trophy_price_by_rank.get(m.rank, 0))
	return 0


## What one unit of a resource fetches: its price × sell_share, at least 1.
static func resource_sell_price(data: ContentData, res: StringName) -> int:
	return maxi(1, floori(int(data.balance.shop.resource_prices.get(res, 0)) * data.balance.shop.sell_share))


## Sells one trophy or one unit of a resource; returns the money paid (0 = nothing to sell).
static func sell(run: RunState, data: ContentData, id: StringName) -> int:
	var ws := run.workshop
	if ws.amount(id) <= 0:
		return 0
	var paid := 0
	if data.balance.workshop.resources.has(id):
		paid = resource_sell_price(data, id)
		ws.resources[id] -= 1
	else:
		paid = trophy_price(data, id)
		ws.trophies[id] -= 1
		if ws.trophies[id] <= 0:
			ws.trophies.erase(id)
	run.money += paid
	return paid


## After a fight: consumables of the bag that were played are used up (one bag copy per played card). Only the bag
## gives consumables today; if gear ever does, bag cards will need their own mark.
static func spend_bag(run: RunState, s: CombatState) -> void:
	for c: CardInstance in s.exhaust_pile:
		if c.def.type == &"consumable" and run.bag.has(c.def.id):
			run.bag.erase(c.def.id)
