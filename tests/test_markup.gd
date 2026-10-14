extends TestSuite
## The F3 markup editor (GDD 20.12): chains of links, cutting a link, deleting and renaming nodes with their references,
## corners on shared edges, the open fog side, the camera box, and the data-file layout writer.


func _map(data: ContentData) -> DistrictMapDef:
	return data.district_maps[&"GREY"]


func test_chain_link_and_unlink() -> void:
	var data := load_content(false)
	var map := _map(data)
	var a := MapMarkupOps.add_node(map, Vector2(1500, 1500))
	var b := MapMarkupOps.add_node(map, Vector2(1600, 1500))
	var st := MapMarkupOps.link(map, null, map.home, a)
	eq(MapMarkupOps.link(map, st, a, b), st, "the chain extends the same street")
	eq(st.nodes, [map.home, a, b] as Array[StringName], "street nodes in chain order")
	check((map.adjacency[a] as Array).has(b), "a and b are neighbours")
	var streets := map.streets.size()
	MapMarkupOps.unlink(map, map.home, a)
	check(not (map.adjacency[a] as Array).has(map.home), "the link is gone")
	check((map.adjacency[a] as Array).has(b), "the rest of the street stays")
	eq(map.streets.size(), streets, "the one-link head is dropped, the tail kept")


func test_delete_and_rename_node() -> void:
	var data := load_content(false)
	var map := _map(data)
	var life := data.life(&"GREY")
	check(MapMarkupOps.delete_node(map, life, map.home) != "", "the home node cannot be deleted")
	var lm := map.landmarks[0]
	var old := lm.node
	eq(MapMarkupOps.rename_node(map, life, old, &"renamed_node"), "", "renamed")
	eq(lm.node, &"renamed_node", "the place follows the rename")
	check(map.streets.any(func(s: DistrictMapDef.StreetDef) -> bool: return s.nodes.has(&"renamed_node")), "streets follow")
	check(MapMarkupOps.rename_node(map, life, &"renamed_node", &"Bad Id") != "", "a bad id is refused")
	check(MapMarkupOps.rename_node(map, life, &"renamed_node", map.home) != "", "a taken id is refused")
	var lone := MapMarkupOps.add_node(map, Vector2(1500, 1500))
	eq(MapMarkupOps.delete_node(map, life, lone), "", "a free node is deleted")
	check(not map.nodes.has(lone), "gone from the nodes")


func test_corners_on_shared_edges() -> void:
	var data := load_content(false)
	var map := _map(data)
	var contour := map.contour.size()
	var fog := map.fog_side.size()
	MapMarkupOps.add_corner(map, &"contour", Vector2(3440, 3000))  # the Ringwall edge both polygons share
	eq(map.contour.size(), contour + 1, "a corner on the outline")
	eq(map.fog_side.size(), fog + 1, "the fog side shares the edge and gets it too")
	eq(MapMarkupOps.delete_corner(map, Vector2(3440, 3000)), "", "deleted")
	eq(map.contour.size(), contour, "outline back")
	eq(map.fog_side.size(), fog, "fog side back")


func test_fog_side_and_camera_box() -> void:
	var data := load_content(false)
	var map := _map(data)
	check(map.fog_side.size() >= 3, "GREY has an open fog side")
	var box := map.contour_box()
	for p: Vector2 in map.contour:
		check(box.grow(0.5).has_point(p), "the box holds every outline corner")
	map.fog_side = PackedVector2Array([Vector2.ZERO, Vector2.ONE])
	var errs := ErrorLog.new()
	DistrictMapValidator.validate(data, errs, false)
	check(" ".join(errs.messages).contains("fog_side"), "a fog side of 2 points fails")


func test_resident_copy() -> void:
	var data := load_content(false)
	var life := data.life(&"GREY")
	var source := MapMarkupOps.standing(life)[0]
	var r := MapMarkupOps.add_resident(life, source, Vector2(1650, 1550))
	check(r.id != source.id, "a new id")
	eq(r.art, source.art, "the same look")
	eq(r.pos, Vector2(1650, 1550), "at the click")
	check(MapMarkupOps.rename_resident(life, r, source.id) != "", "a taken id is refused")


func test_json_layout_round_trip() -> void:
	for path: String in ["res://data/city/district_maps/GREY.json", "res://data/city/district_life/GREY.json"]:
		var text := FileAccess.get_file_as_string(path)
		eq(JsonLayout.format(JSON.parse_string(text)), text, "%s keeps its layout" % path)


func test_filter_hides_from_picking() -> void:
	var data := load_content(false)
	var map := _map(data)
	var ed := MapMarkupEditor.new(map, data.life(&"GREY"))
	var node_pos := map.node_pos(map.home)
	check(ed.pick(node_pos, 5.0), "a shown node is picked")
	ed.layers[&"streets"] = false
	ed.clear()
	ed.pick(node_pos, 5.0)
	check(ed.node == &"", "a hidden node is not picked")
	var z := map.zones[0]
	ed.layers[StringName("zone:" + z.id)] = false
	ed.layers[&"contour"] = false
	ed.layers[&"fog"] = false
	var corner := z.polygon[0]
	var others := map.zones.filter(func(o: DistrictMapDef.ZoneDef) -> bool: return o != z and o.polygon.has(corner))
	for o: DistrictMapDef.ZoneDef in others:
		ed.layers[StringName("zone:" + o.id)] = false
	ed.layers[&"places"] = false
	ed.layers[&"residents"] = false
	check(not ed.pick(corner, 3.0), "a corner of hidden zones is not picked")

