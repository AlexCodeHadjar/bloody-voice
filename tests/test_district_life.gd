extends TestSuite
## District life (map-life-people.md): the Grey Chapels life data loads and validates, the validator catches a missing
## picture, a position outside the contour and an unknown node; walking views and weighted picks; the layer builds.

const GREY := &"GREY"


func test_grey_life_loads_and_is_valid() -> void:
	var data := load_content()
	var l := data.life(GREY)
	check(l != null, "GREY life is loaded")
	if l == null:
		return
	eq(l.period, &"evening", "evening for now")
	check(l.residents.size() >= 30, "locals, roles, animals and groups are listed")
	check(l.walker_count >= 15, "about twenty passers-by")
	check(not l.kinds_for(&"evening").is_empty(), "walker kinds for the evening")
	check(l.kinds_for(&"evening").size() < l.kinds.size(), "kinds are filtered by period")


func test_validator_reports_broken_life() -> void:
	var data := load_content(false)
	var l := data.life(GREY)
	for r: DistrictLifeDef.ResidentDef in l.residents:
		if r.id == &"grisl":
			r.nodes = [&"nowhere", &"home"] as Array[StringName]
		if r.id == &"tobias":
			r.pos = Vector2(-500, -500)
	l.scenes[0].art = "scene__does_not_exist"
	var errs := ErrorLog.new()
	DistrictLifeValidator.validate(data, errs, true)
	var text := "; ".join(errs.messages)
	check(text.contains("unknown node 'nowhere'"), "unknown node is reported: %s" % text)
	check(text.contains("outside the district contour"), "position outside the contour is reported")
	check(text.contains("scene__does_not_exist"), "missing art file is reported")


func test_facing_picks_view_and_mirror() -> void:
	check(LifeFacing.is_towards(Vector2(-1, 1), false), "down = towards")
	check(not LifeFacing.is_towards(Vector2(1, -1), true), "up = away")
	check(LifeFacing.is_towards(Vector2(1, 0.01), true), "flat keeps the current view")
	check(not LifeFacing.is_flipped(true, Vector2(-1, 1), true), "towards, going left: as painted")
	check(LifeFacing.is_flipped(true, Vector2(1, 1), false), "towards, going right: mirrored")
	check(not LifeFacing.is_flipped(false, Vector2(1, -1), true), "away, going right: as painted")
	check(LifeFacing.is_flipped(false, Vector2(-1, -1), false), "away, going left: mirrored")


func test_weighted_index() -> void:
	var w: Array[float] = [1.0, 3.0, 0.0, 2.0]
	eq(LifeFacing.weighted_index(w, 0.5), 0, "first")
	eq(LifeFacing.weighted_index(w, 1.5), 1, "second")
	eq(LifeFacing.weighted_index(w, 4.5), 3, "skips zero weight")
	eq(LifeFacing.weighted_index(w, 99.0), 3, "past the end gives the last")


func test_layer_builds_and_runs() -> void:
	var data := load_content(false)
	var l := data.life(GREY)
	var layer := LifeLayer.new()
	layer.setup(data.district_map(GREY), data)
	var expected := l.residents.size() + l.walker_count + l.scenes.size()
	for p: DistrictLifeDef.PropDef in l.fx:
		expected += p.points.size()
	eq(layer.get_child_count(), expected, "one node per resident, scene and effect point")
	layer.free()
