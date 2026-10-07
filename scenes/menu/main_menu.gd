extends Control
## Title screen: New game / Continue / Quit over the city map.

const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"
const BACKGROUND := "res://art/city/map/HALLOWDEEP__map__normal.webp"


func _ready() -> void:
	theme = UiKit.theme()
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.SOOT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art := TextureRect.new()
	art.texture = UiKit.texture(BACKGROUND)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.55, 0.5, 0.5)
	add_child(art)
	var shade := ColorRect.new()
	shade.color = Palette.SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := UiKit.label("BLOODY VOICE", 84, Palette.BLOOD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Palette.SOOT)
	title.add_theme_constant_override("font_outline_size", 10)
	box.add_child(title)
	var sub := UiKit.label("The city of Hallowdeep listens. So does the blood.", 22, Palette.FOG)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(Control.new())

	var new_btn := UiKit.button("New Hunt")
	new_btn.pressed.connect(_on_new)
	box.add_child(new_btn)
	var cont_btn := UiKit.button("Continue")
	cont_btn.disabled = not SaveService.has_save()
	cont_btn.pressed.connect(_on_continue)
	box.add_child(cont_btn)
	var quit_btn := UiKit.button("Quit")
	quit_btn.pressed.connect(get_tree().quit)
	box.add_child(quit_btn)
	for b: Button in [new_btn, cont_btn, quit_btn]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	new_btn.grab_focus.call_deferred()


func _on_new() -> void:
	GameState.new_game()
	GameState.save_game()
	get_tree().change_scene_to_file(CITY_MAP)


func _on_continue() -> void:
	if GameState.continue_game():
		get_tree().change_scene_to_file(CITY_MAP)
