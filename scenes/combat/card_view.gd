class_name CardView
extends PanelContainer
## One card in the hand: cost, name, type, text. Emits `chosen` when clicked.

signal chosen(uid: int)

const SIZE := Vector2(176, 246)
const TYPE_COLORS: Dictionary[StringName, Color] = {
	&"attack": Color("8a1c1c"), &"support": Color("6e7a8a"), &"consumable": Color("4f7a4a"),
	&"capture": Color("b08a4a"), &"rage": Color("a0302a"), &"curse": Color("3a3340"),
}

var uid: int = 0
var _box: StyleBoxFlat


func setup(card: CardInstance, playable: bool, selected: bool) -> void:
	uid = card.uid
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var def := card.def
	_box = UiKit.panel_box(Color(0.93, 0.89, 0.80), TYPE_COLORS.get(def.type, Palette.BRASS))
	_box.set_border_width_all(4 if not selected else 7)
	if selected:
		_box.border_color = Palette.BRASS_LIGHT
	add_theme_stylebox_override("panel", _box)
	modulate = Color.WHITE if playable else Color(0.6, 0.6, 0.6)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	top.add_child(UiKit.label("%d" % def.cost if not def.unplayable else "—", 26, Palette.BLOOD))
	var name_label := UiKit.label(def.name, 19, Palette.SOOT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(name_label)
	var kind := String(def.type).capitalize() + ("   · ammo %d" % def.ammo if def.ammo > 0 else "")
	var kind_row := HBoxContainer.new()
	kind_row.add_child(Icons.rect("CARD_TYPE", def.type, 24))
	kind_row.add_child(UiKit.label(kind, 14, TYPE_COLORS.get(def.type, Palette.INK_MUTED)))
	v.add_child(kind_row)
	v.add_child(UiKit.paragraph(def.text, 16, Palette.SOOT))
	for c: Node in v.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(uid)
		accept_event()
