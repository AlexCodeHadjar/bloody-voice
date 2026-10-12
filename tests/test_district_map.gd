extends TestSuite
## District map (GDD 20): the Grey Chapels map loads and validates, the validator catches broken maps, walking
## rules (paths, routes, spots) and point lookups (landmark, zone, ambience).

const GREY := &"GREY"


func test_grey_map_loads_and_is_valid() -> void:
	var data := load_content()
	var m := data.district_map(GREY)
	check(m != null, "GREY map is loaded")
	if m == null:
		return
	eq(m.landmarks.size(), 21, "landmark count")
	eq(m.home, &"home", "home node")
	check(m.landmark(&"ash_garret") != null, "landmark lookup by id")
	eq(m.landmark(&"rusty_cog").name, "Мастерская «Ржавая Шестерня»", "landmark names are Russian")
	check(m.landmark(&"rusty_cog").desc != "", "landmark has a description")


func test_path_from_home_to_every_landmark() -> void:
	var m := load_content(false).district_map(GREY)
	for l: DistrictMapDef.LandmarkDef in m.landmarks:
		var path := DistrictMapRules.shortest_path(m, m.home, l.node)
		check(not path.is_empty() and path[0] == m.home and path[-1] == l.node, "path home -> %s" % l.id)


func test_shortest_path_picks_the_shorter_route() -> void:
	var m := _tiny()
	eq(DistrictMapRules.shortest_path(m, &"A", &"C"), [&"A", &"B", &"C"] as Array[StringName], "via B, not D")
	eq(DistrictMapRules.shortest_path(m, &"C", &"A"), [&"C", &"B", &"A"] as Array[StringName], "back the same way")
	eq(DistrictMapRules.shortest_path(m, &"A", &"A"), [&"A"] as Array[StringName], "same node")
	eq(DistrictMapRules.shortest_path(m, &"A", &"Z"), [] as Array[StringName], "unknown node")


func test_route_on_same_edge_and_across_edges() -> void:
	var m := _tiny()
	var s1 := DistrictMapRules.nearest_spot(m, Vector2(30, 5), 20.0)
	var s2 := DistrictMapRules.nearest_spot(m, Vector2(80, -5), 20.0)
	check(s1.point.is_equal_approx(Vector2(30, 0)), "spot is projected onto the street")
	_same_line(DistrictMapRules.route(m, s1, s2), [Vector2(30, 0), Vector2(80, 0)], "same edge goes straight")
	var s3 := DistrictMapRules.nearest_spot(m, Vector2(105, 40), 20.0)
	_same_line(DistrictMapRules.route(m, s1, s3), [Vector2(30, 0), Vector2(100, 0), Vector2(100, 40)], "across edges via B")
	eq(DistrictMapRules.nearest_node(m, s1), &"A", "closer end of the edge")
	eq(DistrictMapRules.nearest_node(m, s2), &"B", "closer end of the edge (east)")
	var at_c := DistrictMapRules.spot_at_node(m, &"C")
	_same_line(DistrictMapRules.route(m, s1, at_c), [Vector2(30, 0), Vector2(100, 0), Vector2(100, 100)], "to a node")


func test_nearest_spot_respects_max_dist() -> void:
	var m := _tiny()
	check(DistrictMapRules.nearest_spot(m, Vector2(50, 60), 20.0) == null, "too far from every street")
	check(DistrictMapRules.nearest_spot(m, Vector2(50, 10), 20.0) != null, "close enough")
	var at_node := DistrictMapRules.nearest_spot(m, Vector2(100, 0), 5.0)
	eq(at_node.a, at_node.b, "exactly at a node")


func test_lookups_on_grey() -> void:
	var m := load_content(false).district_map(GREY)
	var home := m.node_pos(&"home")
	eq(DistrictMapRules.landmark_at(m, m.landmark(&"ash_garret").pos).id, &"ash_garret", "landmark under its own point")
	check(DistrictMapRules.landmark_at(m, Vector2(3700, 300)) == null, "no landmark far away")
	eq(DistrictMapRules.zone_at(m, home), &"ash_quarter", "home is in the Ash Quarter")
	eq(DistrictMapRules.zone_at(m, m.node_pos(&"cellars")), &"fog_hollow", "cellars are in the Fog Hollow")
	eq(DistrictMapRules.ambience_at(m, m.node_pos(&"cellars")), &"cellar", "cellar sound")
	eq(DistrictMapRules.ambience_at(m, m.node_pos(&"square")), &"fire", "bonfire sound spot wins over the zone")
	eq(DistrictMapRules.ambience_at(m, m.node_pos(&"north_gate")), &"", "nothing special at the north gate")
	check(DistrictMapRules.inside(m, home), "home is inside the contour")
	check(not DistrictMapRules.inside(m, Vector2(10, 10)), "corner is outside the contour")


func test_validator_catches_broken_maps() -> void:
	var data := load_content(false)
	var m := data.district_map(GREY)
	m.nodes[&"lonely"] = m.node_pos(&"home") + Vector2(10, 10)
	m.nodes[&"far_away"] = Vector2(5, 5)
	m.landmarks[0].node = &"nowhere"
	m.landmarks[1].action = &"dance"
	m.landmarks[2].zone = &"no_zone"
	m.zones[0].ambience = &"no_sound"
	var errs := ErrorLog.new()
	DistrictMapValidator.validate(data, errs, false)
	for needle: String in ["'lonely' is not on any street", "'lonely' is not connected", "'far_away' is outside the contour",
			"unknown node 'nowhere'", "unknown action 'dance'", "unknown zone 'no_zone'", "unknown ambience 'no_sound'"]:
		check(_has(errs.messages, needle), "validator reports: %s" % needle)


func test_validator_catches_duplicate_landmark_and_bad_district() -> void:
	var data := load_content(false)
	var m := data.district_map(GREY)
	m.landmarks[1].id = m.landmarks[0].id
	m.district = &"NOWHERE"
	var errs := ErrorLog.new()
	DistrictMapValidator.validate(data, errs, false)
	check(_has(errs.messages, "duplicate landmark id"), "duplicate landmark id")
	check(_has(errs.messages, "unknown district 'NOWHERE'"), "unknown district")


func test_bad_district_map_json_is_reported() -> void:
	var errs := ErrorLog.new()
	DistrictMapDef.from_dict({"district": "X", "contour": [[1]], "streets": [{"id": "s", "name": "S", "kind": "wide", "nodes": ["a"]}]}, errs, "t")
	check(_has(errs.messages, "a point must be"), "bad point")
	check(_has(errs.messages, "unknown kind"), "bad street kind")
	check(_has(errs.messages, "at least 2 nodes"), "short street")


## A loop A-B-C plus a long detour A-D-C: the short way from A to C is through B.
func _tiny() -> DistrictMapDef:
	var errs := ErrorLog.new()
	var m := DistrictMapDef.from_dict({
		"district": "T", "image": "", "image_size": [400, 400], "home": "A",
		"contour": [[-50, -50], [200, -50], [200, 400], [-50, 400]],
		"zones": [], "neighbours": [],
		"nodes": {"A": [0, 0], "B": [100, 0], "C": [100, 100], "D": [0, 300]},
		"streets": [{"id": "s1", "name": "S1", "kind": "street", "nodes": ["A", "B", "C"]},
			{"id": "s2", "name": "S2", "kind": "alley", "nodes": ["A", "D", "C"]}],
		"landmarks": []}, errs, "tiny")
	check(errs.is_empty(), "tiny map is valid: %s" % "; ".join(errs.messages))
	return m


func _same_line(line: PackedVector2Array, expected: Array[Vector2], message: String) -> void:
	eq(line.size(), expected.size(), message + " (points)")
	for i: int in mini(line.size(), expected.size()):
		check(line[i].is_equal_approx(expected[i]), "%s: point %d is %s" % [message, i, line[i]])


func _has(messages: PackedStringArray, needle: String) -> bool:
	for msg: String in messages:
		if msg.contains(needle):
			return true
	return false
