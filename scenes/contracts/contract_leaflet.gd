class_name ContractLeaflet
extends TextureButton
## One leaflet pinned on the tavern board (GDD 7.1): type, danger rank, the creature's black silhouette, reward
## and deadline; a wax seal once the hunter took it. Lifts a little under the mouse.

const SIZE := Vector2(236, 384)
const PAPER := "res://art/ui/RUMOR__leaflet.webp"
const SEAL := "res://art/ui/WAX__seal.webp"
const INK := Color(0.16, 0.12, 0.1)  ## printed text on the paper

var contract: ContractsState.Contract


func setup(c: ContractsState.Contract) -> void:
	contract = c
	texture_normal = UiKit.texture(PAPER)
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = SIZE
	pivot_offset = SIZE * 0.5
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 30
	box.offset_right = -30
	box.offset_top = 64  # below the nail
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.add_child(_head())
	box.add_child(UiKit.picture(ContractKit.silhouette(c), Vector2(0, 130)))
	box.add_child(_line(ContractKit.monster_name(c), 19, INK))
	box.add_child(Icons.with_text("RESOURCE", &"money", str(c.reward), 26, 20, INK))
	box.add_child(_line(ContractKit.deadline_text(c), 15, ContractKit.deadline_color(c, INK)))
	if c.accepted or c.done:
		add_child(_seal())
	mouse_entered.connect(_lift.bind(true))
	mouse_exited.connect(_lift.bind(false))


func _head() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(Icons.rect("CONTRACT", contract.type, 30))
	var t := _line(ContractKit.type_name(contract), 16, INK)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	h.add_child(Icons.rect("RANK", StringName(ContractKit.rank(contract).to_lower()), 30))
	return h


func _line(text: String, size: int, color: Color) -> Label:
	var l := UiKit.paragraph(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The hunter's wax seal over the lower half (taken) — dimmed when the contract is already done.
func _seal() -> TextureRect:
	var s := UiKit.picture(UiKit.texture(SEAL), Vector2(120, 120))
	s.position = Vector2(SIZE.x - 140, SIZE.y - 150)
	s.size = Vector2(120, 120)
	s.rotation = -0.25
	if contract.done:
		s.modulate = Color(1, 1, 1, 0.55)
	return s


func _lift(on: bool) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector2.ONE * (1.06 if on else 1.0), 0.12)
	if on:
		UiKit.sound(&"ui.hover")
