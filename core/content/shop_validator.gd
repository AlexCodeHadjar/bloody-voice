class_name ShopValidator
extends RefCounted
## Checks the shop, tavern and rent numbers (GDD 11.1, 3.2–3.3): slots of known kinds, every resource priced,
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
