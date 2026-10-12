class_name MapMarkupSaver
extends RefCounted
## Debug builds only (F3 on the district map): writes the street nodes, landmark spots and zone corners the owner moved
## back into data/city/district_maps/<ID>.json. Only the numbers change — every "<node>": [x, y] in "nodes", every
## landmark's "pos": [x, y] and every zone's "polygon" — so the file keeps its layout. Run from the editor the data folder is writable; an
## exported build writes user://district_maps/<ID>.json instead. Returns the path written, or "" on failure.


static func save(map: DistrictMapDef) -> String:
	var res := "res://data/city/district_maps/%s.json" % map.district
	var text := FileAccess.get_file_as_string(res)
	if text == "":
		return ""
	for id: StringName in map.nodes:
		var p := map.nodes[id]
		text = _replace(text, "(\"%s\": )\\[-?\\d+, -?\\d+\\]" % id, p)
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		text = _replace(text, "(\"id\": \"%s\"[^}]*?\"pos\": )\\[-?\\d+, -?\\d+\\]" % lm.id, lm.pos)
	for z: DistrictMapDef.ZoneDef in map.zones:
		var re := RegEx.create_from_string("(\"id\": \"%s\"[^}]*?\"polygon\": )\\[[-\\d,\\[\\] ]*\\]" % z.id)
		if re.search(text) == null:
			push_warning("markup: zone '%s' not found in the map file, its corners are not saved" % z.id)
		text = re.sub(text, "$1" + _polygon(z.polygon))
	var path := res
	var f := FileAccess.open(res, FileAccess.WRITE)
	if f == null:  # an exported build: the data folder is read-only
		DirAccess.make_dir_recursive_absolute("user://district_maps")
		path = "user://district_maps/%s.json" % map.district
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(text)
	f.close()
	return path


static func _replace(text: String, pattern: String, p: Vector2) -> String:
	var re := RegEx.create_from_string(pattern)
	return re.sub(text, "$1[%d, %d]" % [roundi(p.x), roundi(p.y)])


static func _polygon(poly: PackedVector2Array) -> String:
	var parts := PackedStringArray()
	for p: Vector2 in poly:
		parts.append("[%d, %d]" % [roundi(p.x), roundi(p.y)])
	return "[" + ", ".join(parts) + "]"
