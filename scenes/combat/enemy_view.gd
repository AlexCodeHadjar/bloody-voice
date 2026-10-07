class_name EnemyView
extends PanelContainer
## The creature's card: its art (phase art once it changes phase), name, rank, HP, block, statuses
## and clickable body parts.

signal body_clicked
signal part_clicked(part_id: StringName)

const ART_SIZE := Vector2(260, 390)

var _art: TextureRect
var _title: Label
var _hp: StatBar
var _statuses: HBoxContainer
var _parts: HBoxContainer
var _targeting := false


func _ready() -> void:
	custom_minimum_size = Vector2(860, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	add_child(h)
	_art = TextureRect.new()
	_art.custom_minimum_size = ART_SIZE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_art)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	_title = UiKit.label("", 30, Palette.BRASS_LIGHT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_hp = StatBar.new().setup(Palette.BLOOD, 520.0, 17, &"hp")
	v.add_child(_hp)
	_statuses = HBoxContainer.new()
	_statuses.add_theme_constant_override("separation", 12)
	_statuses.custom_minimum_size = Vector2(0, 30)
	v.add_child(_statuses)
	_parts = HBoxContainer.new()
	_parts.add_theme_constant_override("separation", 8)
	v.add_child(_parts)


func refresh(e: EnemyCombatant, targeting: bool, parts_allowed: bool) -> void:
	_targeting = targeting
	var border := Palette.BRASS_LIGHT if targeting else Palette.BRASS
	var box := UiKit.panel_box(Color(0.08, 0.06, 0.06, 0.9), border)
	box.set_border_width_all(4 if targeting else 2)
	add_theme_stylebox_override("panel", box)
	var phase_art := e.def.art_path("combat", "phase2")
	_art.texture = UiKit.texture(phase_art if e.next_phase > 0 and ResourceLoader.exists(phase_art) else e.def.art_path("combat"))
	_title.text = "%s   [%s]" % [e.display_name, e.def.rank]
	_hp.show_value("HP", e.hp, e.max_hp)
	Icons.fill_statuses(_statuses, e)
	for c: Node in _parts.get_children():
		c.queue_free()
	for id: StringName in e.part_order:
		var p: PartState = e.parts[id]
		var b := UiKit.button("%s\n%s" % [p.def.name, "BROKEN" if p.broken else "%d / %d" % [p.hp, p.def.hp]], 15)
		b.custom_minimum_size = Vector2(150, 56)
		b.disabled = p.broken or not (targeting and parts_allowed)
		b.pressed.connect(part_clicked.emit.bind(id))
		_parts.add_child(b)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if _targeting and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		body_clicked.emit()
		accept_event()
