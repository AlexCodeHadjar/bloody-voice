class_name ShopGenerator
extends RefCounted
## The Rag-and-Bone table of a week (GDD 17.2 ShopGenerator v1): ready modules, blueprints the hunter does not know,
## consumables, resource lots. Prices come from resource values (balance.json/shop). Pure: same rng, same table.


static func generate(data: ContentData, run: RunState, rng: RandomNumberGenerator, first_uid: int) -> Array[ShopState.Item]:
	var b := data.balance.shop
	var out: Array[ShopState.Item] = []
	var modules: Array[StringName] = []
	for id: StringName in data.modules:
		modules.append(id)
	var unknown: Array[StringName] = []
	for id: StringName in data.blueprint_order:
		if not run.workshop.blueprints.has(id):
			unknown.append(id)
	var consumables: Array[StringName] = []
	for id: StringName in b.consumables:
		consumables.append(id)
	var lots: Array[StringName] = []
	for id: StringName in b.lots:
		lots.append(id)
	var picks: Dictionary[StringName, Array] = {&"module": modules, &"blueprint": unknown, &"consumable": consumables,
		&"resource": lots}
	for kind: StringName in ShopDefs.KINDS:
		var pool: Array[StringName] = []
		pool.assign(picks[kind])
		for id: StringName in SeededRng.sample(pool, int(b.slots.get(kind, 0)), rng):
			out.append(_item(data, kind, id, rng, first_uid + out.size()))
	return out


static func _item(data: ContentData, kind: StringName, id: StringName, rng: RandomNumberGenerator, uid: int) -> ShopState.Item:
	var b := data.balance.shop
	var x := ShopState.Item.new()
	x.uid = uid
	x.kind = kind
	x.id = id
	match kind:
		&"module":
			x.price = round_price(data, value(data, data.blueprint(id).cost) * b.module_mult)
		&"blueprint":
			x.price = round_price(data, value(data, data.blueprint(id).cost) * b.blueprint_mult)
		&"consumable":
			x.price = b.consumables[id]
		&"resource":
			x.amount = rng.randi_range(b.lots[id].x, b.lots[id].y)
			x.price = x.amount * int(b.resource_prices.get(id, 0))
	return x


## Money worth of the resources in a cost (trophies are not counted).
static func value(data: ContentData, cost: Dictionary) -> float:
	var v := 0.0
	for k: Variant in cost:
		v += float(data.balance.shop.resource_prices.get(StringName(str(k)), 0)) * int(cost[k])
	return v


static func round_price(data: ContentData, v: float) -> int:
	var step := data.balance.shop.price_step
	return maxi(step, roundi(v / step) * step)
