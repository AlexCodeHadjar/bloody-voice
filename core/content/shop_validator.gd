class_name ShopValidator
extends RefCounted
## Checks the shop, tavern, rent, health and progress numbers (GDD 11.1, 3.2–3.3, 4): slots, every resource priced,
## consumables are consumable cards, trophy prices cover every rank, gossip exists.


static func validate(data: ContentData, errs: ErrorLog) -> void:
	var b := data.balance.shop
	var w := "balance.json/shop"
	for kind: StringName in b.slots:
		if not ShopDefs.KINDS.has(kind) or b.slots[kind] < 0:
			errs.add(w, "slots: unknown kind '%s' or a negative count" % kind)
	for res: StringName in data.balance.workshop.resources:
		if b.resource_prices.get(res, 0) <= 0:
			errs.add(w, "resource '%s' needs a price > 0" % res)
	for res: StringName in b.lots:
		if not data.balance.workshop.resources.has(res) or b.lots[res].x < 1 or b.lots[res].y < b.lots[res].x:
			errs.add(w, "lots/%s: a resource with 1 <= min <= max" % res)
	for id: StringName in b.consumables:
		var c := data.card(id)
		if c == null or c.type != &"consumable" or b.consumables[id] <= 0:
			errs.add(w, "consumables: '%s' must be a consumable card with a price > 0" % id)
	for m: MonsterDef in data.monsters.values():
		if not b.trophy_price_by_rank.has(m.rank):
			errs.add(w, "trophy_price_by_rank has no rank '%s'" % m.rank)
	if b.bag_size < 1 or b.price_step < 1 or b.sell_share <= 0.0 or b.sell_share > 1.0:
		errs.add(w, "bag_size and price_step must be >= 1, sell_share in (0, 1]")
	var t := data.balance.tavern
	if t.shift_money_min < 0 or t.shift_money_max < t.shift_money_min or t.overheard_true_chance < 0.0 or t.overheard_true_chance > 1.0:
		errs.add("balance.json/tavern", "need 0 <= shift_money_min <= shift_money_max and a chance in 0..1")
	if data.rumor_data.gossip.is_empty():
		errs.add("rumors/rumors.json", "needs at least one gossip line")
	if data.balance.debt_strikes < 1:
		errs.add("balance.json/economy", "debt_strikes must be >= 1")
	var h := data.balance.health
	if h.rest_share <= 0.0 or h.rest_share > 1.0 or h.treat_base < 0 or h.treat_per_hp < 0 or h.treat_per_sanity < 0 or h.fall_fee < 0:
		errs.add("balance.json/health", "rest_share in (0, 1], prices >= 0")
	_progress(data, errs)


static func _progress(data: ContentData, errs: ErrorLog) -> void:
	var p := data.balance.progress
	var w := "balance.json/progress"
	if p.level_cap < 1 or p.xp_base < 1 or p.xp_per_level < 0 or p.attribute_point_every < 1:
		errs.add(w, "level_cap, xp_base and attribute_point_every must be >= 1, xp_per_level >= 0")
	for m: MonsterDef in data.monsters.values():
		if not p.xp_by_rank.has(m.rank):
			errs.add(w, "xp_by_rank has no rank '%s'" % m.rank)
	for a: StringName in p.start_attributes:
		if not ProgressDefs.ATTRIBUTES.has(a):
			errs.add(w, "start_attributes: unknown attribute '%s'" % a)
