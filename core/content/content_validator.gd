class_name ContentValidator
extends RefCounted
## Cross-checks loaded content. Any error here stops the game at boot (GDD 19.6).


static func validate(data: ContentData, errs: ErrorLog, check_files: bool = true) -> void:
	_balance(data, errs)
	_districts(data, errs, check_files)
	_states(data, errs)
	_regions(data, errs, check_files)


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
