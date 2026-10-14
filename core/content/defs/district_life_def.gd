class_name DistrictLifeDef
extends RefCounted
## Life on one district map (data/city/district_life/<ID>.json, map-life-people.md): passers-by, groups, local
## characters, roles, animals, standing scenes and effects. Atmosphere only. Positions are map art pixels.

const MODES: Array[StringName] = [&"wander", &"stand", &"work", &"circle", &"dash"]
const FX_KINDS: Array[StringName] = [&"flicker", &"smoke", &"ripple", &"sway", &"static", &"breathe"]
const PERIODS: Array[StringName] = [&"day", &"evening", &"night", &"rain"]


class WalkerKind:
	var set_id: StringName  ## pass_* sheet: 4 persons, slots 1-2, 3-4, 5-6, 7-8 (towards, away)
	var weight: float
	var speed: float
	var periods: Array[StringName] = []
	var scale: float = 1.0  ## of the common figure height (children are smaller)


class ResidentDef:
	var group: StringName  ## walking_groups | locals | roles | animals
	var id: StringName
	var art: StringName  ## sheet name, e.g. locals_1
	var slot: int  ## first picture (towards); the second one is slot + 1
	var mode: StringName
	var single: bool  ## one picture only (no "away" view)
	var pos: Vector2
	var to: Vector2  ## dash: the other end
	var nodes: Array[StringName] = []
	var speed: float
	var chat: bool
	var radius: float  ## circle: flight radius
	var interval: Vector2  ## dash: seconds between runs (min, max)
	var fade_near: float  ## > 0: melts away while the hero is this close
	var fade_back: Vector2  ## seconds before coming back (min, max)
	var scale: float = 1.0  ## multiplier of the common figure scale

	## The sheet slots this resident can show.
	func slots() -> Array[int]:
		var out: Array[int] = [slot]
		var two := mode == &"work" or (mode == &"wander" and not single) or fade_near > 0.0
		if two:
			out.append(slot + 1)
		return out


class PropDef:
	var art: String  ## file name after LIFE__, e.g. fx__bonfire, scene__funeral
	var art_b: String  ## second frame (kind sway)
	var kind: StringName
	var scale: float  ## 0 = the common scene scale
	var additive: bool
	var rate: float
	var amp: float
	var rise: float
	var points: PackedVector2Array = PackedVector2Array()


var district: StringName
var period: StringName
var figure_scale: float
var figure_height: float  ## art px every person stands at, whatever the size of the picture (owner 2026-10-14); 0 = figure_scale
var scene_scale: float
var emote_scale: float
var shadow: float  ## shadow width relative to the figure width
var var_scale: float  ## +- random size, share
var var_speed: float
var var_value: float  ## +- random darkening of the clothes
var walker_count: int
var kinds: Array[WalkerKind] = []
var residents: Array[ResidentDef] = []
var scenes: Array[PropDef] = []
var fx: Array[PropDef] = []


static func from_dict(d: Dictionary, errs: ErrorLog, where: String) -> DistrictLifeDef:
	var x := DistrictLifeDef.new()
	x.district = DefReader.id(d, "district", errs, where)
	x.period = DefReader.id(d, "period", errs, where)
	var sc := DefReader.dict(d, "scales", errs, where)
	x.figure_scale = DefReader.number(sc, "figure", errs, where + "/scales")
	x.figure_height = DefReader.number(sc, "figure_height", errs, where + "/scales", 0.0, false)
	x.scene_scale = DefReader.number(sc, "scene", errs, where + "/scales")
	x.emote_scale = DefReader.number(sc, "emote", errs, where + "/scales")
	x.shadow = DefReader.number(sc, "shadow", errs, where + "/scales")
	var v := DefReader.dict(sc, "variation", errs, where + "/scales")
	x.var_scale = DefReader.number(v, "scale", errs, where + "/scales/variation")
	x.var_speed = DefReader.number(v, "speed", errs, where + "/scales/variation")
	x.var_value = DefReader.number(v, "value", errs, where + "/scales/variation")
	var w := DefReader.dict(d, "walkers", errs, where)
	x.walker_count = DefReader.integer(w, "count", errs, where + "/walkers")
	for k: Variant in DefReader.array(w, "kinds", errs, where + "/walkers"):
		x.kinds.append(_kind(_object(k, errs, where + "/walkers"), errs, where + "/walkers"))
	for group: String in ["walking_groups", "locals", "roles", "animals"]:
		for r: Variant in DefReader.array(d, group, errs, where):
			x.residents.append(_resident(StringName(group), _object(r, errs, where + "/" + group), errs, where + "/" + group))
	for s: Variant in DefReader.array(d, "scenes", errs, where):
		x.scenes.append(_prop(_object(s, errs, where + "/scenes"), errs, where + "/scenes", &"breathe"))
	for f: Variant in DefReader.array(d, "fx", errs, where):
		x.fx.append(_prop(_object(f, errs, where + "/fx"), errs, where + "/fx", &""))
	return x


func kinds_for(p: StringName) -> Array[WalkerKind]:
	var out: Array[WalkerKind] = []
	for k: WalkerKind in kinds:
		if k.periods.has(p):
			out.append(k)
	return out


static func figure_path(sheet: StringName, slot: int) -> String:
	return "res://art/ui/life/LIFE__%s__%d.webp" % [sheet, slot]


static func prop_path(art: String) -> String:
	return "res://art/ui/LIFE__%s.webp" % art


static func _kind(kd: Dictionary, errs: ErrorLog, where: String) -> WalkerKind:
	var k := WalkerKind.new()
	k.set_id = DefReader.id(kd, "set", errs, where)
	k.weight = DefReader.number(kd, "weight", errs, where + "/" + k.set_id)
	k.speed = DefReader.number(kd, "speed", errs, where + "/" + k.set_id)
	k.periods = DefReader.ids(kd, "periods", errs, where + "/" + k.set_id)
	k.scale = DefReader.number(kd, "scale", errs, where + "/" + k.set_id, 1.0, false)
	return k


static func _resident(group: StringName, rd: Dictionary, errs: ErrorLog, where: String) -> ResidentDef:
	var r := ResidentDef.new()
	r.group = group
	r.id = DefReader.id(rd, "id", errs, where)
	var w := where + "/" + r.id
	r.art = DefReader.id(rd, "art", errs, w)
	r.slot = DefReader.integer(rd, "slot", errs, w)
	r.mode = DefReader.id(rd, "mode", errs, w)
	r.single = DefReader.flag(rd, "single")
	r.pos = _point(rd, "pos", errs, w, r.mode != &"wander")
	r.to = _point(rd, "to", errs, w, r.mode == &"dash")
	r.nodes = DefReader.ids(rd, "nodes", errs, w)
	r.speed = DefReader.number(rd, "speed", errs, w, 0.0, r.mode in [&"wander", &"circle", &"dash"])
	r.chat = DefReader.flag(rd, "chat", false)
	r.radius = DefReader.number(rd, "radius", errs, w, 0.0, r.mode == &"circle")
	r.interval = _pair(rd, "interval", errs, w, r.mode == &"dash")
	r.fade_near = DefReader.number(rd, "fade_near", errs, w, 0.0, false)
	r.fade_back = _pair(rd, "fade_back", errs, w, r.fade_near > 0.0)
	r.scale = DefReader.number(rd, "scale", errs, w, 1.0, false)
	return r


static func _prop(pd: Dictionary, errs: ErrorLog, where: String, default_kind: StringName) -> PropDef:
	var p := PropDef.new()
	p.art = DefReader.string(pd, "art", errs, where)
	var w := where + "/" + p.art
	p.art_b = DefReader.string(pd, "art_b", errs, w, false)
	p.kind = StringName(str(pd.get("kind", default_kind)))
	p.scale = DefReader.number(pd, "scale", errs, w, 0.0, false)
	p.additive = DefReader.flag(pd, "additive")
	p.rate = DefReader.number(pd, "rate", errs, w, 0.0, false)
	p.amp = DefReader.number(pd, "amp", errs, w, 0.0, false)
	p.rise = DefReader.number(pd, "rise", errs, w, 0.0, false)
	if pd.has("points"):
		for pt: Variant in DefReader.array(pd, "points", errs, w):
			p.points.append(_vec(pt, errs, w))
	else:
		p.points.append(_point(pd, "pos", errs, w, true))
	return p


static func _object(v: Variant, errs: ErrorLog, where: String) -> Dictionary:
	if typeof(v) != TYPE_DICTIONARY:
		errs.add(where, "every entry must be an object")
		return {}
	return v


static func _point(d: Dictionary, key: String, errs: ErrorLog, where: String, required: bool) -> Vector2:
	if not d.has(key):
		if required:
			errs.add(where, "missing '%s'" % key)
		return Vector2.ZERO
	return _vec(d[key], errs, where + "/" + key)


static func _pair(d: Dictionary, key: String, errs: ErrorLog, where: String, required: bool) -> Vector2:
	return _point(d, key, errs, where, required)


static func _vec(v: Variant, errs: ErrorLog, where: String) -> Vector2:
	var a: Array = v as Array if typeof(v) == TYPE_ARRAY else []
	if a.size() != 2 or not _is_num(a[0]) or not _is_num(a[1]):
		errs.add(where, "must be [x, y]")
		return Vector2.ZERO
	return Vector2(float(a[0]), float(a[1]))


static func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT
