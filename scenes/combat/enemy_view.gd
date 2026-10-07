class_name EnemyView
extends PanelContainer
## The creature's card: name, rank, HP, block, statuses and clickable body parts.

signal body_clicked
signal part_clicked(part_id: StringName)

var _title: Label
var _hp: StatBar
var _info: Label
var _parts: HBoxContainer
var _targeting := false


func _ready() -> void:
	custom_minimum_size = Vector2(560, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	_title = UiKit.label("", 30, Palette.BRASS_LIGHT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_hp = StatBar.new().setup(Palette.BLOOD, 520.0)
	v.add_child(_hp)
	_info = UiKit.label("", 17, Palette.FOG)
	v.add_child(_info)
	_parts = HBoxContainer.new()
	_parts.add_theme_constant_override("separation", 8)
	v.add_child(_parts)


func refresh(e: EnemyCombatant, targeting: bool, parts_allowed: bool) -> void:
	_targeting = targeting
	var border := Palette.BRASS_LIGHT if targeting else Palette.BRASS
	var box := UiKit.panel_box(Color(0.08, 0.06, 0.06, 0.9), border)
	box.set_border_width_all(4 if targeting else 2)
	add_theme_stylebox_override("panel", box)
	_title.text = "%s   [%s]" % [e.display_name, e.def.rank]
	_hp.show_value("HP", e.hp, e.max_hp)
	_info.text = "Block %d    %s" % [e.block, StatusText.of(e)]
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
