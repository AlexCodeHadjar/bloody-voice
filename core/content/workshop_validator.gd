class_name WorkshopValidator
extends RefCounted
## Checks workshop content (GDD 6): every module and mechanism has a blueprint, costs name known resources or
## trophies, unlock trophies exist, modules have tiers II–III with known cards and an upgrade cost for each,
## loot covers every rank and names known resources.


static func validate(data: ContentData, errs: ErrorLog) -> void:
	var w := "gear/blueprints.json"
	var trophies := data.trophy_ids()
	var starts := 0
	for bp: WorkshopDefs.BlueprintDef in data.blueprints.values():
		var bw := "%s/%s" % [w, bp.item]
		var known := data.modules.has(bp.item) if bp.kind == &"module" else data.mechanism(bp.item) != null
		if not WorkshopDefs.KINDS.has(bp.kind) or not known:
			errs.add(bw, "no %s '%s'" % [bp.kind, bp.item])
		starts += 1 if bp.start else 0
		if bp.unlock != &"" and not trophies.has(bp.unlock):
			errs.add(bw, "unlock trophy '%s' no creature drops" % bp.unlock)
		if not bp.start and bp.unlock == &"":
			errs.add(bw, "needs start: true or an unlock trophy")
		_amounts(data, bp.cost, trophies, errs, bw + "/cost")
		for u: Dictionary in bp.upgrade:
			_amounts(data, u, trophies, errs, bw + "/upgrade")
		if bp.kind == &"module" and bp.upgrade.size() != ModuleDef.MAX_TIER - 1:
			errs.add(bw, "a module needs %d upgrade costs" % (ModuleDef.MAX_TIER - 1))
	if starts == 0:
		errs.add(w, "at least one blueprint must be known at the start")
	for id: StringName in data.modules:
		_tiers(data, data.module(id), errs)
		if data.blueprint(id) == null:
			errs.add(w, "module '%s' has no blueprint" % id)
	for id: StringName in data.mechanisms:
		if data.blueprint(id) == null:
			errs.add(w, "mechanism '%s' has no blueprint" % id)
	_balance(data, trophies, errs)


static func _tiers(data: ContentData, m: ModuleDef, errs: ErrorLog) -> void:
	var w := "gear/modules.json/%s" % m.id
	if m.tiers.size() != ModuleDef.MAX_TIER - 1:
		errs.add(w, "needs tiers II and III")
	for t: ModuleDef.TierDef in m.tiers:
		for c: StringName in t.cards + t.capture_cards:
			if not data.cards.has(c):
				errs.add(w + "/tiers", "unknown card '%s'" % c)


static func _balance(data: ContentData, trophies: Array[StringName], errs: ErrorLog) -> void:
	var b := data.balance.workshop
	var w := "balance.json/workshop"
	if b.resources.is_empty() or b.crafts_per_day < 1 or b.salvage_share < 0.0 or b.salvage_share > 1.0:
		errs.add(w, "needs resources, crafts_per_day >= 1 and salvage_share in 0..1")
	_amounts(data, b.start_resources, trophies, errs, w + "/start_resources")
	for m: MonsterDef in data.monsters.values():
		if not b.loot_by_rank.has(m.rank):
			errs.add(w, "loot_by_rank has no rank '%s' (monster %s)" % [m.rank, m.id])
		_amounts(data, m.loot, [], errs, "monsters/%s/loot" % m.id)
	for rank: String in b.loot_by_rank:
		_amounts(data, b.loot_by_rank[rank], [], errs, w + "/loot_by_rank/" + rank)


## Keys must be resources (or trophies where allowed); amounts > 0.
static func _amounts(data: ContentData, a: Dictionary, trophies: Array[StringName], errs: ErrorLog, w: String) -> void:
	for k: Variant in a:
		var id := StringName(str(k))
		if not data.balance.workshop.resources.has(id) and not trophies.has(id):
			errs.add(w, "unknown resource or trophy '%s'" % id)
		if int(a[k]) <= 0:
			errs.add(w, "'%s' must be > 0" % id)
