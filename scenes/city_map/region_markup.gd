class_name RegionMarkup
extends RefCounted
## F3 on the city map (debug builds, owner 2026-10-14): the districts' borders on the city map — the outline you click
## to choose a district — and where the hunter figure stands. Separate from the district close-up map (its own data).
## A click picks a corner or a figure point; Ctrl + the held left button moves it (a corner shared by neighbouring
## districts moves in all of them); right click adds a corner on the nearest border or deletes the picked one;
## Ctrl+S checks and writes data/city/map_regions.json in its own layout.

const PICK := 12.0  ## screen px
const PATH := "res://data/city/map_regions.json"
const LINE := Color(0.35, 0.8, 1.0)
const ANCHOR := Color(1.0, 0.85, 0.4)

var on := false
var map: MapRegionsDef
var _corners: Array = []  ## [Region, index] at the picked corner
var _anchor: MapRegionsDef.Region = null  ## the region whose figure point is picked
var _at := Vector2.INF  ## the picked point, image px
var _offset := Vector2.ZERO
var moving := false
var moved_anchors: Dictionary[StringName, bool] = {}  ## regions whose figure point the file must get


func _init(regions: MapRegionsDef) -> void:
	map = regions


func clear() -> void:
	_corners = []
	_anchor = null
	_at = Vector2.INF
	moving = false


func has_pick() -> bool:
	return _at != Vector2.INF


## Picks a figure point or a corner within `radius` image px of `p`.
func pick(p: Vector2, radius: float) -> bool:
	for r: MapRegionsDef.Region in map.regions:
		if r.center.distance_to(p) <= radius:
			clear()
			_anchor = r
			_at = r.center
			return true
	for r: MapRegionsDef.Region in map.regions:
		for q: Vector2 in r.polygon:
			if q.distance_to(p) <= radius:
				_pick_corner(q)
				return true
	return false


func _pick_corner(at: Vector2) -> void:
	clear()
	_at = at
	for r: MapRegionsDef.Region in map.regions:
		for i: int in r.polygon.size():
			if r.polygon[i].distance_to(at) < 0.5:
				_corners.append([r, i])


func start_move(mouse: Vector2) -> void:
	moving = true
	_offset = _at - mouse


func move_to(mouse: Vector2) -> void:
	var p := (mouse + _offset).round()
	if _anchor != null:
		_anchor.center = p
		moved_anchors[_anchor.id] = true
	for c: Array in _corners:
		var r := c[0] as MapRegionsDef.Region
		r.polygon[c[1] as int] = p
	_at = p


## A corner on the border nearest to `p`, in every region that shares that border.
func add_corner(p: Vector2) -> void:
	var best := INF
	var edge: Array[Vector2] = []
	for r: MapRegionsDef.Region in map.regions:
		for i: int in r.polygon.size():
			var a := r.polygon[i]
			var b := r.polygon[(i + 1) % r.polygon.size()]
			var d := Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)
			if d < best:
				best = d
				edge = [a, b]
	if edge.is_empty():
		return
	var at := Geometry2D.get_closest_point_to_segment(p, edge[0], edge[1]).round()
	for r: MapRegionsDef.Region in map.regions:
		for i: int in r.polygon.size():
			var a := r.polygon[i]
			var b := r.polygon[(i + 1) % r.polygon.size()]
			if (a == edge[0] and b == edge[1]) or (a == edge[1] and b == edge[0]):
				r.polygon.insert(i + 1, at)
				break
	_pick_corner(at)


## Removes the picked corner from every region that has it ("" = done).
func delete_corner() -> String:
	if _corners.is_empty():
		return ""
	for c: Array in _corners:
		if (c[0] as MapRegionsDef.Region).polygon.size() <= 3:
			return Loc.t("ui.dev.no_delete_corner")
	for c: Array in _corners:
		var r := c[0] as MapRegionsDef.Region
		r.polygon.remove_at(r.polygon.find(_at))
	clear()
	return ""


func label() -> String:
	if _anchor != null:
		return Loc.t("ui.dev.region_anchor", {"id": _anchor.id})
	var ids := PackedStringArray()
	for c: Array in _corners:
		ids.append(str((c[0] as MapRegionsDef.Region).id))
	return ", ".join(ids)


func picked() -> Vector2:
	return _at


## Every border with its corners, the figure points, the picked point.
func draw(view: CanvasItem, to_screen: Callable) -> void:
	var font := UiKit.serif()
	for r: MapRegionsDef.Region in map.regions:
		var pts := PackedVector2Array()
		for p: Vector2 in r.polygon:
			pts.append(to_screen.call(p) as Vector2)
		pts.append(pts[0])
		view.draw_polyline(pts, LINE, 2.0)
		for p: Vector2 in r.polygon:
			view.draw_rect(Rect2((to_screen.call(p) as Vector2) - Vector2(4, 4), Vector2(8, 8)), LINE)
		var c: Vector2 = to_screen.call(r.center)
		view.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7, 0), c + Vector2(0, 7), c + Vector2(-7, 0)]), ANCHOR)
		view.draw_string(font, c + Vector2(9, -6), str(r.id), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ANCHOR)
	if _at != Vector2.INF:
		view.draw_arc(to_screen.call(_at) as Vector2, 11.0, 0.0, TAU, 24, Color.YELLOW, 3.0)


## Ctrl+S: the city-map checks first (a map the game would not start with is not written), then the file.
func save(data: ContentData) -> String:
	var errs := ErrorLog.new()
	ContentValidator._regions(data, errs, false)
	if not errs.messages.is_empty():
		return Loc.t("ui.dev.map_save_refused", {"n": errs.messages.size(), "first": errs.messages[0]})
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary:
		return Loc.t("ui.dev.map_not_saved")
	for rd: Dictionary in raw["regions"]:
		for r: MapRegionsDef.Region in map.regions:
			if str(r.id) == str(rd["id"]):
				rd["polygon"] = _pts(r.polygon)
				if rd.has("anchor") or moved_anchors.has(r.id):
					rd["anchor"] = [roundi(r.center.x), roundi(r.center.y)]
	var text := JSON.stringify(_whole(raw), " ", false) + "\n"
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return Loc.t("ui.dev.map_not_saved")
	f.store_string(text.replace("\n", "\r\n"))  # the file keeps its Windows line ends
	f.close()
	return Loc.t("ui.dev.map_saved", {"path": PATH})


static func _pts(poly: PackedVector2Array) -> Array:
	var out: Array = []
	for p: Vector2 in poly:
		out.append([roundi(p.x), roundi(p.y)])
	return out


## Whole numbers without «.0», as the file has them.
static func _whole(v: Variant) -> Variant:
	if v is Dictionary:
		var d: Dictionary = v
		for k: Variant in d:
			d[k] = _whole(d[k])
		return d
	if v is Array:
		var a: Array = v
		for i: int in a.size():
			a[i] = _whole(a[i])
		return a
	if v is float and is_equal_approx(v as float, roundf(v as float)):
		return int(v as float)
	return v
