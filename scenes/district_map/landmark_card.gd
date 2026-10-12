class_name LandmarkCard
extends PanelContainer
## The card of a place the hero has walked to (owner, 2026-10-12): name, zone, a line about it and what can be done
## there now — rest at home, crafting in the workshop, the contract board and a shift in the tavern, the shop, the infirmary, the Scriptorium,
## the rumor post on Bonfire Square; gates say why they are shut; the other places say they open later.

signal action_chosen(action: StringName)

const WIDTH := 430.0
## button -> [text key, icon set, icon id]
const BUTTONS: Dictionary[StringName, Array] = {
	&"rest": ["ui.district.action.rest", "ACTION", &"rest"],
	&"workshop": ["ui.district.action.workshop", "ACTION", &"workshop"],
	&"rumors": ["ui.district.action.rumors", "PLACE", &"leaflets"],
	&"tavern": ["ui.district.action.tavern", "ACTION", &"tavern"],
	&"shift": ["ui.district.action.shift", "RESOURCE", &"money"],
	&"shop": ["ui.district.action.shop", "PLACE", &"shop"],
	&"infirmary": ["ui.district.action.infirmary", "PLACE", &"infirmary"],
	&"library": ["ui.district.action.library", "ACTION", &"library"],
}
## a place's action -> its buttons (one button of the same name when not listed)
const PLACE_BUTTONS: Dictionary[StringName, Array] = {&"tavern": [&"tavern", &"shift"]}

var _title: Label
var _zone: Label
var _text: Label
var _buttons: VBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	_title = UiKit.label("", 30, Palette.BRASS_LIGHT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(_title)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(40, 40)
	close.pressed.connect(close_card)
	head.add_child(close)
	_zone = UiKit.label("", 16, Palette.INK_MUTED)
	box.add_child(_zone)
	_text = UiKit.paragraph("", 18)
	box.add_child(_text)
	_buttons = VBoxContainer.new()
	box.add_child(_buttons)
	visible = false


func show_landmark(lm: DistrictMapDef.LandmarkDef, zone_name: String) -> void:
	_title.text = lm.name
	_zone.text = zone_name
	_text.text = lm.desc
	for c: Node in _buttons.get_children():
		c.queue_free()
	var actions: Array = PLACE_BUTTONS.get(lm.action, [lm.action])
	for a: Variant in actions:
		_buttons.add_child(_button_for(a as StringName))
	visible = true
	UiKit.sound(&"ui.open")


func close_card() -> void:
	if visible:
		visible = false
		UiKit.sound(&"ui.close")


func _button_for(action: StringName) -> Button:
	var b: Button
	if BUTTONS.has(action):
		var spec: Array = BUTTONS[action]
		b = Icons.button(spec[1] as String, spec[2] as StringName, Loc.t(spec[0] as String), 20)
		b.pressed.connect(func() -> void: action_chosen.emit(action))
	else:
		var key := "ui.district.action.locked" if action == &"locked" else "ui.district.action.soon"
		b = UiKit.button(Loc.t(key), 20)
		b.disabled = true
	b.custom_minimum_size = Vector2(WIDTH - 40.0, 48)
	return b
