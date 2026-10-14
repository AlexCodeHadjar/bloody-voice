class_name MapMarkupZoneTool
extends RefCounted
## F3 zones (owner 2026-10-14) for MapMarkupUi: outline a new zone with clicks (corners stick to nearby corners and
## borders; right click or Enter closes it, Esc drops it), delete a zone, rename it, and heal the mosaic (ZoneMosaic)
## after every change of a corner so the zones stay without holes or overlaps.

var ui: MapMarkupUi
var drafting := false
var draft := PackedVector2Array()
var rename_target: DistrictMapDef.ZoneDef = null  ## the zone the rename box is for (null = a point)


func _init(owner_ui: MapMarkupUi) -> void:
	ui = owner_ui


func start() -> void:
	drafting = true
	draft = PackedVector2Array()
	_show()
	ui.status(Loc.t("ui.dev.zone_draw"))


func add_point(p: Vector2) -> void:
	draft.append(ZoneMosaic.snap(ui.ed.map, p.round(), DistrictView.EDIT_PICK / ui.view.zoom_level(), PackedVector2Array()))
	_show()
	ui.status(Loc.t("ui.dev.zone_draw_n", {"n": draft.size()}))


## Closes the outline: the new zone is carved out of the zones under it; then the rename box asks for its name.
func finish() -> void:
	var outline := draft
	cancel()
	if outline.size() < 3:
		ui.status(Loc.t("ui.dev.zone_too_small"))
		return
	var map := ui.ed.map
	if ZoneMosaic.is_island(map, outline):
		ui.status(Loc.t("ui.dev.zone_island"))
		return
	var parent := MapMarkupOps.main_zone(map, outline)
	var z := MapMarkupOps.add_zone(map, ContentDB.data, outline, parent)
	if z == null:
		ui.status(Loc.t("ui.dev.zone_outside"))
		return
	if parent != null:
		ui.ed.zone_parents[z.id] = parent.id
	ui.ed.named_zones[z.id] = true
	ui.ed.clear()
	ui.view.show_pick()
	rename_target = z
	ui.open_rename(z.name)


func cancel() -> void:
	drafting = false
	draft = PackedVector2Array()
	_show()


func delete(z: DistrictMapDef.ZoneDef) -> String:
	var problem := MapMarkupOps.delete_zone(ui.ed.map, ContentDB.data, z)
	if problem == "":
		ui.ed.clear()
	return problem


func rename(text: String) -> void:
	if rename_target != null and text != "":
		rename_target.name = text
		ui.ed.named_zones[rename_target.id] = true
	rename_target = null


## Heals the zones (`first` keeps its shape) and keeps the picked corner picked at its new place.
func heal(first: DistrictMapDef.ZoneDef = null) -> void:
	var at := ui.ed.corner
	ZoneMosaic.heal(ui.ed.map, first)
	if at != Vector2.INF:
		var best := at
		var best_d := INF
		for poly: MapMarkupOps.PolyRef in MapMarkupOps.polygons(ui.ed.map):
			for q: Vector2 in poly.points():
				if q.distance_to(at) < best_d:
					best = q
					best_d = q.distance_to(at)
		ui.ed.pick_corner(best)
	ui.view.show_pick()


func _show() -> void:
	ui.view.overlay.draft = draft
	ui.view.overlay.queue_redraw()
