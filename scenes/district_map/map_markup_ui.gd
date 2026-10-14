class_name MapMarkupUi
extends Control
## F3 markup tools over the district map (debug builds, owner 2026-10-14): the legend (what every dot, ring, square and
## line means and the controls), the right-click menu (create a street node, a place, a zone / outline / fog corner,
## a standing resident; connect, rename or delete the point under the mouse; delete a link), the chain mode of
## «Соединить» (each click links the last node to the next one, a click on empty ground makes a new node there;
## right click or Esc ends it) and the rename box. Changes go to the live defs; Ctrl+S saves (MapMarkupSaver).

signal life_changed  ## residents were added, moved, renamed or deleted: the screen rebuilds them

enum { CONNECT = 1, RENAME, DELETE, UNLINK, NEW_NODE = 10, ZONE_CORNER, DARK_CORNER, FOG_CORNER, PLACE = 100, RESIDENT = 200 }

const LINK_PICK := 14.0  ## screen px around a link that a right click hits

var view: DistrictView
var ed: MapMarkupEditor
var chain_from: StringName = &""  ## the chain mode's last node ("" = off)
var _chain_street: DistrictMapDef.StreetDef = null
var _menu := PopupMenu.new()
var _places := PopupMenu.new()
var _people := PopupMenu.new()
var _legend: PanelContainer
var _rename: PanelContainer
var _rename_edit: LineEdit
var _at := Vector2.ZERO  ## art point of the last right click
var _link: Array[StringName] = []  ## the link under the last right click


func setup(district_view: DistrictView) -> void:
	view = district_view
	ed = view.markup
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	for m: PopupMenu in [_menu, _places, _people]:  # the submenus become the menu's children when first added
		m.id_pressed.connect(_on_menu)
	add_child(_menu)
	_legend = MapMarkupLegend.build(ed, func() -> void: view.show_pick())  # a tick redraws the markup
	_legend.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_legend.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_legend.position = Vector2(16.0, -16.0)
	add_child(_legend)
	_build_rename()


## F3 toggles the markup; in it Ctrl+S saves and Esc ends the chain or closes the rename box. True when handled.
func key(event: InputEvent) -> bool:
	if not event is InputEventKey or not (event as InputEventKey).pressed or (event as InputEventKey).echo:
		return false
	var k := event as InputEventKey
	if k.keycode == KEY_F3:
		view.overlay.toggle_debug()
		set_on(view.overlay.debug_visible)
		return true
	if not visible:
		return false
	if k.keycode == KEY_S and k.ctrl_pressed:
		_save()
		return true
	return event.is_action_pressed("ui_cancel") and cancel()


func set_on(on: bool) -> void:
	visible = on
	end_chain()
	_rename.visible = false
	if not on:
		view.end_markup()
	_status(Loc.t("ui.dev.map_help") if on else "")


func is_busy() -> bool:
	return chain_from != &"" or _rename.visible


## Esc in the markup: ends the chain or closes the rename box. True when it did something.
func cancel() -> bool:
	if _rename.visible:
		_rename.visible = false
		return true
	if chain_from != &"":
		end_chain()
		return true
	return false


## A right click on the map (screen position): the menu for what is under the mouse.
func right_click(screen_pos: Vector2) -> void:
	if chain_from != &"":
		end_chain()
		return
	_at = view.screen_to_art(screen_pos)
	_link = []
	var picked := ed.pick(_at, DistrictView.EDIT_PICK / view.zoom_level())
	if not picked:
		ed.clear()
		_link = _link_at(_at, LINK_PICK / view.zoom_level())
	_fill_menu(picked)
	_menu.reset_size()
	_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i.ZERO))
	view.show_pick()


## A left click in the chain mode (art point): link to the node there, or make a new node and link to it.
func chain_click(p: Vector2) -> bool:
	if chain_from == &"":
		return false
	var to := &""
	for id: StringName in ed.map.nodes:
		if ed.map.nodes[id].distance_to(p) <= DistrictView.EDIT_PICK / view.zoom_level():
			to = id
	if to == &"":
		to = MapMarkupOps.add_node(ed.map, p)
	_chain_street = MapMarkupOps.link(ed.map, _chain_street, chain_from, to)
	chain_from = to
	ed.clear()
	ed.node = to
	_status(Loc.t("ui.dev.chain", {"id": to}))
	view.show_pick()
	return true


func end_chain() -> void:
	if chain_from != &"":
		_status(Loc.t("ui.dev.chain_end"))
	chain_from = &""
	_chain_street = null
	view.overlay.chain_from = Vector2.INF
	view.overlay.queue_redraw()


func _fill_menu(picked: bool) -> void:
	_menu.clear()
	if picked:
		if ed.node != &"":
			_menu.add_item(Loc.t("ui.dev.menu_connect"), CONNECT)
		if ed.corner == Vector2.INF:
			_menu.add_item(Loc.t("ui.dev.menu_rename"), RENAME)
		_menu.add_item(Loc.t("ui.dev.menu_delete"), DELETE)
		return
	if not _link.is_empty():
		_menu.add_item(Loc.t("ui.dev.menu_unlink", {"a": _link[0], "b": _link[1]}), UNLINK)
		_menu.add_separator()
	_menu.add_item(Loc.t("ui.dev.menu_node"), NEW_NODE)
	_places.clear()
	for i: int in DistrictMapDef.ACTIONS.size():
		_places.add_item(Loc.t("ui.district.action.%s" % DistrictMapDef.ACTIONS[i]), PLACE + i)
	_menu.add_submenu_node_item(Loc.t("ui.dev.menu_place"), _places)
	_menu.add_item(Loc.t("ui.dev.menu_zone_corner"), ZONE_CORNER)
	_menu.add_item(Loc.t("ui.dev.menu_dark_corner"), DARK_CORNER)
	if not ed.map.fog_side.is_empty():
		_menu.add_item(Loc.t("ui.dev.menu_fog_corner"), FOG_CORNER)
	_people.clear()
	var standing := MapMarkupOps.standing(ed.life)
	for i: int in standing.size():
		_people.add_item(str(standing[i].id), RESIDENT + i)
	if not standing.is_empty():
		_menu.add_submenu_node_item(Loc.t("ui.dev.menu_resident"), _people)


func _on_menu(id: int) -> void:
	var problem := ""
	match id:
		CONNECT:
			chain_from = ed.node
			_status(Loc.t("ui.dev.chain", {"id": chain_from}))
		RENAME:
			_open_rename()
		DELETE:
			problem = _delete()
		UNLINK:
			MapMarkupOps.unlink(ed.map, _link[0], _link[1])
		NEW_NODE:  # a lone node stops the game: the chain starts from it at once (owner 2026-10-14)
			ed.clear()
			ed.node = MapMarkupOps.add_node(ed.map, _at)
			chain_from = ed.node
			_status(Loc.t("ui.dev.chain", {"id": chain_from}))
		ZONE_CORNER, DARK_CORNER, FOG_CORNER:
			var which: StringName = {ZONE_CORNER: &"zone", DARK_CORNER: &"contour", FOG_CORNER: &"fog"}[id]
			MapMarkupOps.add_corner(ed.map, which, _at)
			ed.pick_corner(_at.round())
		_:
			_create(id)
	if problem != "":
		_status(problem)
	elif id != CONNECT and id != NEW_NODE:
		view.show_pick()


func _create(id: int) -> void:
	ed.clear()
	if id >= RESIDENT:
		var source := MapMarkupOps.standing(ed.life)[id - RESIDENT]
		ed.resident = MapMarkupOps.add_resident(ed.life, source, _at)
		ed.copied_residents[ed.resident.id] = source.id
		life_changed.emit()
	elif id >= PLACE:
		ed.landmark = MapMarkupOps.add_place(ed.map, _at, DistrictMapDef.ACTIONS[id - PLACE])


func _delete() -> String:
	var problem := ""
	if ed.node != &"":
		problem = MapMarkupOps.delete_node(ed.map, ed.life, ed.node)
	elif ed.landmark != null:
		problem = MapMarkupOps.delete_place(ed.map, ed.landmark)
	elif ed.resident != null:
		ed.life.residents.erase(ed.resident)
		life_changed.emit()
	else:
		problem = MapMarkupOps.delete_corner(ed.map, ed.corner)
	if problem == "":
		ed.clear()
	return problem


## The two neighbouring nodes of the street segment within `radius` art px of `p` ([] = none).
func _link_at(p: Vector2, radius: float) -> Array[StringName]:
	for s: DistrictMapDef.StreetDef in ed.map.streets:
		for i: int in range(1, s.nodes.size()):
			var a := ed.map.node_pos(s.nodes[i - 1])
			var b := ed.map.node_pos(s.nodes[i])
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= radius:
				return [s.nodes[i - 1], s.nodes[i]]
	return []


func _build_rename() -> void:
	_rename = PanelContainer.new()
	_rename.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	_rename.set_anchors_preset(Control.PRESET_CENTER)
	_rename.custom_minimum_size = Vector2(520, 0)
	_rename.position = Vector2(-260, -60)
	var v := VBoxContainer.new()
	_rename.add_child(v)
	v.add_child(UiKit.label(Loc.t("ui.dev.rename_title"), 20, Palette.BRASS_LIGHT))
	_rename_edit = LineEdit.new()
	_rename_edit.text_submitted.connect(_apply_rename)
	v.add_child(_rename_edit)
	v.add_child(UiKit.label(Loc.t("ui.dev.rename_help"), 15, Palette.FOG))
	_rename.visible = false
	add_child(_rename)


func _open_rename() -> void:
	_rename_edit.text = ed.landmark.name if ed.landmark != null else str(ed.node if ed.node != &"" else ed.resident.id)
	_rename.visible = true
	_rename_edit.grab_focus()
	_rename_edit.select_all()


func _apply_rename(text: String) -> void:
	var to := text.strip_edges()
	var problem := ""
	if ed.landmark != null:
		if to != "":
			ed.landmark.name = to
			ed.named_places[ed.landmark.id] = true
	elif ed.node != &"":
		problem = MapMarkupOps.rename_node(ed.map, ed.life, ed.node, StringName(to))
		if problem == "":
			ed.node = StringName(to)
	elif ed.resident != null:
		var old := ed.resident.id
		problem = MapMarkupOps.rename_resident(ed.life, ed.resident, StringName(to))
		if problem == "":
			ed.note_rename(old, ed.resident.id)
	if problem != "":
		_status(problem)
		return
	_rename.visible = false
	view.show_pick()


## Ctrl+S: checks the map and the residents the way the game does at boot first; a markup the game would not start
## with is NOT written (owner 2026-10-14: a broken save locked him out of F3) — the changes stay here to be fixed.
func _save() -> void:
	var errs := ErrorLog.new()
	DistrictMapValidator.validate(ContentDB.data, errs, false)
	DistrictLifeValidator.validate(ContentDB.data, errs, false)
	if not errs.messages.is_empty():
		_status(Loc.t("ui.dev.map_save_refused", {"n": errs.messages.size(), "first": errs.messages[0]}))
		return
	var path := MapMarkupSaver.save(ed)
	_status(Loc.t("ui.dev.map_saved", {"path": path}) if path != "" else Loc.t("ui.dev.map_not_saved"))
	life_changed.emit()


func _status(text: String) -> void:
	view.set_dev_text(text)
