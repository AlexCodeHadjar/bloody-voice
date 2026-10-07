class_name ContentValidator
extends RefCounted
## Cross-checks loaded content. Any error here stops the game at boot (GDD 19.6).


static func validate(data: ContentData, errs: ErrorLog, check_files: bool = true) -> void:
	_balance(data, errs)
	_districts(data, errs, check_files)
	_states(data, errs)
	_regions(data, errs, check_files)
	_cards(data, errs)
	_monsters(data, errs)
	GearValidator.validate(data, errs)


static func _balance(data: ContentData, errs: ErrorLog) -> void:
	var b := data.balance
	var w := "balance.json"
	if b.days_per_week < 1:
		errs.add(w, "days_per_week must be >= 1")
	for pair: Array in [["rent_weekday", b.rent_weekday], ["shop_refresh_weekday", b.shop_refresh_weekday]]:
		var v: int = pair[1]
		if v < 0 or v >= b.days_per_week:
			errs.add(w, "%s must be in 0..%d" % [pair[0], b.days_per_week - 1])
	if b.base_hp <= 0 or b.base_ap <= 0 or b.hand_size <= 0:
		errs.add(w, "hero base_hp, base_ap and hand_size must be > 0")
	if b.capture_max_chance <= 0.0 or b.capture_max_chance > 1.0:
		errs.add(w, "capture max_chance must be in (0, 1]")
	if not data.districts.has(b.start_district):
		errs.add(w, "hero start_district '%s' is not a district" % b.start_district)
	if b.starter_deck.is_empty():
		errs.add(w, "hero starter_deck is empty")
	for card_id: StringName in b.starter_deck:
		if not data.cards.has(card_id):
			errs.add(w, "starter_deck card '%s' does not exist" % card_id)
	if not data.cards.has(b.panic_card):
		errs.add(w, "combat panic_card '%s' does not exist" % b.panic_card)


static func _districts(data: ContentData, errs: ErrorLog, check_files: bool) -> void:
	var symbols := {}
	for d: DistrictDef in data.districts.values():
		var w := "districts.json/%s" % d.id
		if d.symbol.length() != 1:
			errs.add(w, "symbol must be one character")
		elif symbols.has(d.symbol):
			errs.add(w, "symbol '%s' already used by %s" % [d.symbol, symbols[d.symbol]])
		symbols[d.symbol] = d.id
		if d.area_ids.is_empty():
			errs.add(w, "needs at least one area")
		if check_files:
			for kind: String in ["tile", "scene"]:
				if not ResourceLoader.exists(d.art_path(kind)):
					errs.add(w, "missing art %s" % d.art_path(kind))


static func _states(data: ContentData, errs: ErrorLog) -> void:
	if not data.district_states.has(&"normal"):
		errs.add("district_states.json", "state 'normal' is required")
	for s: DistrictStateDef in data.district_states.values():
		if s.next != &"" and not data.district_states.has(s.next):
			errs.add("district_states.json/%s" % s.id, "next state '%s' does not exist" % s.next)
		if s.ring_growth_mult <= 0.0 or s.shop_price_mult <= 0.0:
			errs.add("district_states.json/%s" % s.id, "multipliers must be > 0")


static func _regions(data: ContentData, errs: ErrorLog, check_files: bool) -> void:
	var m := data.map_regions
	var covered := {}
	if check_files and not ResourceLoader.exists(m.image):
		errs.add("map_regions.json", "missing image %s" % m.image)
	for r: MapRegionsDef.Region in m.regions:
		if not data.districts.has(r.district):
			errs.add("map_regions.json/%s" % r.id, "unknown district '%s'" % r.district)
		if r.polygon.size() < 3:
			errs.add("map_regions.json/%s" % r.id, "polygon needs at least 3 points")
		covered[r.district] = true
	for id: StringName in data.districts:
		if not covered.has(id):
			errs.add("map_regions.json", "district %s has no region on the map" % id)


static func _cards(data: ContentData, errs: ErrorLog) -> void:
	for c: CardDef in data.cards.values():
		var w := "cards/%s" % c.id
		if not CardDef.TYPES.has(c.type):
			errs.add(w, "unknown type '%s'" % c.type)
		if not CardDef.TARGETS.has(c.target):
			errs.add(w, "unknown target '%s'" % c.target)
		if c.cost < 0 or c.ammo < 0:
			errs.add(w, "cost and ammo must be >= 0")
		_effects(c.effects, data, errs, w)


static func _monsters(data: ContentData, errs: ErrorLog) -> void:
	for m: MonsterDef in data.monsters.values():
		var w := "monsters/%s" % m.id
		if m.hp <= 0 or m.intents_per_turn < 1:
			errs.add(w, "hp must be > 0 and intents_per_turn >= 1")
		var removable := {}
		for p: MonsterDef.PartDef in m.parts:
			if p.hp <= 0:
				errs.add(w, "part %s needs hp > 0" % p.id)
			for mv: StringName in p.removes:
				removable[mv] = true
				_need_move(m, mv, errs, w + "/parts/" + p.id)
		var safe := false
		for mv: StringName in m.deck:
			_need_move(m, mv, errs, w + "/deck")
			safe = safe or not removable.has(mv)
		if not safe:
			errs.add(w, "deck needs at least one move that no body part removes")
		for ph: MonsterDef.PhaseDef in m.phases:
			if ph.below <= 0.0 or ph.below >= 1.0:
				errs.add(w, "phase '%s': below must be in (0, 1)" % ph.name)
			for mv: StringName in ph.add + ph.remove:
				_need_move(m, mv, errs, w + "/phases")
		for move: MonsterDef.MoveDef in m.moves.values():
			_effects(move.effects, data, errs, w + "/moves/" + move.id)
		for d: StringName in m.districts:
			if not data.districts.has(d):
				errs.add(w, "unknown district '%s'" % d)


static func _need_move(m: MonsterDef, move_id: StringName, errs: ErrorLog, w: String) -> void:
	if not m.moves.has(move_id):
		errs.add(w, "unknown move '%s'" % move_id)


static func _effects(effects: Array[Dictionary], data: ContentData, errs: ErrorLog, w: String) -> void:
	for e: Dictionary in effects:
		var problem := EffectSchema.check(e)
		if problem != "":
			errs.add(w, problem)
		elif StringName(str(e["op"])) == &"add_card" and not data.cards.has(StringName(str(e["card"]))):
			errs.add(w, "add_card: unknown card '%s'" % e["card"])
