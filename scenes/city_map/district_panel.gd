class_name DistrictPanel
extends PanelContainer
## Right-side card about one district: establishing art + facts from DistrictDef.

var _art: TextureRect
var _title: Label
var _icon: TextureRect
var _state: HBoxContainer
var _facts: Label
var _look: Label
var _hint: Label


func _ready() -> void:
	custom_minimum_size = Vector2(520, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_art = TextureRect.new()
	_art.custom_minimum_size = Vector2(0, 420)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(_art)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	_icon = Icons.rect("DISTRICT", &"", 44)
	head.add_child(_icon)
	_title = UiKit.label("", 30, Palette.BRASS_LIGHT)
	head.add_child(_title)
	_state = HBoxContainer.new()
	box.add_child(_state)
	_facts = UiKit.paragraph("", 17, Palette.PARCHMENT)
	box.add_child(_facts)
	_look = UiKit.paragraph("", 16, Palette.FOG)
	box.add_child(_look)
	_hint = UiKit.paragraph("", 15, Palette.INK_MUTED)
	box.add_child(_hint)


func show_district(d: DistrictDef, state: StringName, is_hero_here: bool) -> void:
	if d == null:
		return
	_art.texture = UiKit.texture(d.art_path("scene", String(state)))
	if _art.texture == null:
		_art.texture = UiKit.texture(d.art_path("scene"))
	_title.text = d.name
	_icon.texture = Icons.texture("DISTRICT", StringName(String(d.id).to_lower()))
	for c: Node in _state.get_children():
		c.queue_free()
	if state != &"normal":
		_state.add_child(Icons.with_text("STATE", state, String(state).capitalize(), 32, 18, Palette.BRASS_LIGHT))
	var areas: PackedStringArray = []
	for a: StringName in d.area_ids:
		areas.append(d.area_names[a])
	_facts.text = "%s\nControlled by: %s\nDanger: %s\nAreas: %s" % [d.district_class, d.controller, d.danger, ", ".join(areas)]
	_look.text = d.look
	_hint.text = "The hunter is here." if is_hero_here else "Click to send the hunter here."
