class_name MapMarkupSaver
extends RefCounted
## Debug builds only (F3 on the district map, Ctrl+S): writes the markup the owner changed back into
## data/city/district_maps/<ID>.json (outline, fog side, zones, nodes, streets, places, home) and
## data/city/district_life/<ID>.json (standing residents, walkers' nodes) in the files' own layout (JsonLayout),
## keeping every field the editor does not touch (new streets and places get their id as the working English name);
## the Russian names of new or renamed places and new streets go into
## locale/strings.csv. Run from the editor the project is writable; an exported build writes user://district_maps/.
## Returns the paths written, or "" on failure.

const LIFE_GROUPS: Array[String] = ["walking_groups", "locals", "roles", "animals"]
const CSV := "res://locale/strings.csv"


static func save(ed: MapMarkupEditor) -> String:
	var map := ed.map
	var map_path := "res://data/city/district_maps/%s.json" % map.district
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(map_path))
	if not raw is Dictionary:
		return ""
	var names := _sync_map(raw as Dictionary, ed)
	var written := PackedStringArray([_write(map_path, JsonLayout.format(raw))])
	if ed.life != null:
		var life_path := "res://data/city/district_life/%s.json" % map.district
		var life_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(life_path))
		if life_raw is Dictionary:
			_sync_life(life_raw as Dictionary, ed)
			written.append(_write(life_path, JsonLayout.format(life_raw)))
	if not names.is_empty():
		_upsert_csv(names)
	return "" if written.has("") else ", ".join(written)


## Returns the locale rows to write: key -> Russian text.
static func _sync_map(raw: Dictionary, ed: MapMarkupEditor) -> Dictionary[String, String]:
	var map := ed.map
	var base := "district_map.%s" % map.district
	var names: Dictionary[String, String] = {}
	raw["home"] = str(map.home)
	raw["contour"] = _pts(map.contour)
	if map.fog_side.is_empty():
		raw.erase("fog_side")
	else:
		raw["fog_side"] = _pts(map.fog_side)
	for zd: Dictionary in raw["zones"]:
		var z := map.zone(StringName(str(zd["id"])))
		if z != null:
			zd["polygon"] = _pts(z.polygon)
	var nodes := {}
	for id: StringName in map.nodes:
		nodes[str(id)] = _pt(map.nodes[id])
	raw["nodes"] = nodes
	var old := _by_id(raw["streets"] as Array)
	var streets: Array = []
	for s: DistrictMapDef.StreetDef in map.streets:
		var d: Dictionary = (old[str(s.id)] as Dictionary).duplicate() if old.has(str(s.id)) else {"id": str(s.id), "name": str(s.id), "kind": str(s.kind)}
		if not old.has(str(s.id)):
			names["%s.street.%s" % [base, s.id]] = s.name
		d["nodes"] = Array(s.nodes).map(func(n: StringName) -> String: return str(n))
		streets.append(d)
	raw["streets"] = streets
	raw["landmarks"] = _landmarks(raw["landmarks"] as Array, ed, names, base)
	return names


static func _landmarks(list: Array, ed: MapMarkupEditor, names: Dictionary[String, String], base: String) -> Array:
	var old := _by_id(list)
	var out: Array = []
	for lm: DistrictMapDef.LandmarkDef in ed.map.landmarks:
		var d: Dictionary = (old[str(lm.id)] as Dictionary).duplicate() if old.has(str(lm.id)) else {"id": str(lm.id),
			"number": lm.number, "name": str(lm.id), "zone": str(lm.zone), "radius": lm.radius, "action": str(lm.action)}
		d["pos"] = _pt(lm.pos)
		d["node"] = str(lm.node)
		if not old.has(str(lm.id)) or ed.named_places.has(lm.id):
			names["%s.landmark.%s.name" % [base, lm.id]] = lm.name
		out.append(d)
	return out


static func _sync_life(raw: Dictionary, ed: MapMarkupEditor) -> void:
	var old := {}
	for g: String in LIFE_GROUPS:
		old[g] = _by_id(raw.get(g, []) as Array)
		raw[g] = []
	for r: DistrictLifeDef.ResidentDef in ed.life.residents:
		var g := str(r.group)
		var by_id: Dictionary = old[g]
		var src := str(ed.copied_residents.get(r.id, ed.file_id(r)))
		if not by_id.has(src):
			continue
		var d: Dictionary = (by_id[src] as Dictionary).duplicate(true)
		d["id"] = str(r.id)
		if d.has("pos"):
			d["pos"] = _pt(r.pos)
		if d.has("nodes"):
			d["nodes"] = Array(r.nodes).map(func(n: StringName) -> String: return str(n))
		(raw[g] as Array).append(d)


static func _by_id(list: Array) -> Dictionary:
	var out := {}
	for d: Variant in list:
		if d is Dictionary:
			out[str((d as Dictionary).get("id", ""))] = d
	return out


static func _pt(p: Vector2) -> Array:
	return [roundi(p.x), roundi(p.y)]


static func _pts(poly: PackedVector2Array) -> Array:
	var out: Array = []
	for p: Vector2 in poly:
		out.append(_pt(p))
	return out


static func _write(res: String, text: String) -> String:
	var path := res
	var f := FileAccess.open(res, FileAccess.WRITE)
	if f == null:  # an exported build: the project folder is read-only
		DirAccess.make_dir_recursive_absolute("user://district_maps")
		path = "user://district_maps/" + res.get_file()
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(text)
	f.close()
	return path


## Sets the Russian text of each key in the locale table (adds the row when new; English stays or copies Russian).
static func _upsert_csv(names: Dictionary[String, String]) -> void:
	var lines := FileAccess.get_file_as_string(CSV).split("\n")
	for key: String in names:
		var row := "%s,%s,%s" % [key, _q(names[key]), _q(names[key])]
		var found := false
		for i: int in lines.size():
			if lines[i].begins_with(key + ","):
				var cells := lines[i].rsplit(",", true, 1)  # keep the English column when it has no comma
				row = "%s,%s,%s" % [key, _q(names[key]), cells[1] if cells.size() == 2 and not cells[1].ends_with("\"") else _q(names[key])]
				lines[i] = row
				found = true
		if not found:
			lines.insert(lines.size() - 1 if lines[-1] == "" else lines.size(), row)
	var f := FileAccess.open(CSV, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines))
		f.close()


static func _q(text: String) -> String:
	return "\"%s\"" % text.replace("\"", "\"\"")
