class_name DistrictLifeValidator
extends RefCounted
## Checks district life (data/city/district_life, map-life-people.md): art files, nodes, positions inside the contour.


static func validate(data: ContentData, errs: ErrorLog, check_files: bool = true) -> void:
	for l: DistrictLifeDef in data.district_life.values():
		var w := "district_life/%s" % l.district
		var m := data.district_map(l.district)
		if m == null:
			errs.add(w, "no district map for '%s'" % l.district)
			continue
		if not DistrictLifeDef.PERIODS.has(l.period):
			errs.add(w, "unknown period '%s'" % l.period)
		_numbers(l, errs, w)
		_walkers(l, errs, w, check_files)
		var ids := {}
		for r: DistrictLifeDef.ResidentDef in l.residents:
			if ids.has(r.id):
				errs.add(w, "duplicate resident id '%s'" % r.id)
			ids[r.id] = true
			_resident(r, m, errs, w + "/" + r.id, check_files)
		for p: DistrictLifeDef.PropDef in l.scenes + l.fx:
			_prop(p, m, errs, w + "/" + p.art, check_files)
		if check_files:
			for slot: int in range(1, 9):
				_file(DistrictLifeDef.figure_path(&"emote", slot), errs, w + "/emote")


static func _numbers(l: DistrictLifeDef, errs: ErrorLog, w: String) -> void:
	for pair: Array in [["figure", l.figure_scale], ["scene", l.scene_scale], ["emote", l.emote_scale]]:
		if not _in(float(pair[1]), 0.05, 3.0):
			errs.add(w + "/scales", "%s scale must be in 0.05..3" % pair[0])
	if not _in(l.shadow, 0.0, 1.5):
		errs.add(w + "/scales", "shadow must be in 0..1.5")
	for v: float in [l.var_scale, l.var_speed, l.var_value]:
		if not _in(v, 0.0, 0.5):
			errs.add(w + "/scales/variation", "variation must be in 0..0.5")
	if l.walker_count < 0 or l.walker_count > 100:
		errs.add(w + "/walkers", "count must be in 0..100")


static func _walkers(l: DistrictLifeDef, errs: ErrorLog, w: String, check_files: bool) -> void:
	for k: DistrictLifeDef.WalkerKind in l.kinds:
		var kw := "%s/walkers/%s" % [w, k.set_id]
		if k.weight <= 0.0:
			errs.add(kw, "weight must be > 0")
		if not _in(k.speed, 5.0, 400.0):
			errs.add(kw, "speed must be in 5..400")
		for p: StringName in k.periods:
			if not DistrictLifeDef.PERIODS.has(p):
				errs.add(kw, "unknown period '%s'" % p)
		if check_files:
			for slot: int in range(1, 9):
				_file(DistrictLifeDef.figure_path(k.set_id, slot), errs, kw)
	if l.walker_count > 0 and l.kinds_for(l.period).is_empty():
		errs.add(w + "/walkers", "no walker kind for the period '%s'" % l.period)


static func _resident(r: DistrictLifeDef.ResidentDef, m: DistrictMapDef, errs: ErrorLog, w: String, check_files: bool) -> void:
	if not DistrictLifeDef.MODES.has(r.mode):
		errs.add(w, "unknown mode '%s'" % r.mode)
	if r.slot < 1 or r.slot > 8:
		errs.add(w, "slot must be in 1..8")
	elif check_files:
		for s: int in r.slots():
			_file(DistrictLifeDef.figure_path(r.art, s), errs, w)
	if r.mode != &"wander":
		_inside(m, r.pos, errs, w)
	if r.mode == &"dash":
		_inside(m, r.to, errs, w)
		if r.interval.x <= 0.0 or r.interval.y < r.interval.x:
			errs.add(w, "interval must be [min, max] with min > 0")
	if r.mode == &"circle" and not _in(r.radius, 20.0, 800.0):
		errs.add(w, "radius must be in 20..800")
	if r.mode == &"wander" and r.nodes.size() < 2:
		errs.add(w, "wandering needs at least 2 nodes")
	for n: StringName in r.nodes:
		if not m.has_node_id(n):
			errs.add(w, "unknown node '%s'" % n)
	if r.mode in [&"wander", &"circle", &"dash"] and not _in(r.speed, 5.0, 400.0):
		errs.add(w, "speed must be in 5..400")
	if not _in(r.scale, 0.2, 3.0):
		errs.add(w, "scale must be in 0.2..3")
	if r.fade_near > 0.0 and (r.fade_back.x <= 0.0 or r.fade_back.y < r.fade_back.x):
		errs.add(w, "fade_back must be [min, max] with min > 0")


static func _prop(p: DistrictLifeDef.PropDef, m: DistrictMapDef, errs: ErrorLog, w: String, check_files: bool) -> void:
	if not DistrictLifeDef.FX_KINDS.has(p.kind):
		errs.add(w, "unknown kind '%s'" % p.kind)
	if p.kind == &"sway" and p.art_b == "":
		errs.add(w, "sway needs art_b")
	if p.scale != 0.0 and not _in(p.scale, 0.05, 3.0):
		errs.add(w, "scale must be in 0.05..3")
	if p.points.is_empty():
		errs.add(w, "no points")
	for pt: Vector2 in p.points:
		_inside(m, pt, errs, w)
	if check_files:
		_file(DistrictLifeDef.prop_path(p.art), errs, w)
		if p.art_b != "":
			_file(DistrictLifeDef.prop_path(p.art_b), errs, w)


static func _inside(m: DistrictMapDef, p: Vector2, errs: ErrorLog, w: String) -> void:
	if not Geometry2D.is_point_in_polygon(p, m.contour):
		errs.add(w, "position %s is outside the district contour" % p)


static func _file(path: String, errs: ErrorLog, w: String) -> void:
	if not ResourceLoader.exists(path):
		errs.add(w, "missing art %s" % path)


static func _in(v: float, lo: float, hi: float) -> bool:
	return v >= lo and v <= hi
