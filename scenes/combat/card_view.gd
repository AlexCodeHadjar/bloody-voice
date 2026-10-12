class_name CardView
extends Control
## One card (GDD 21.3): parchment frame by type, cost cog, name, art window, type, text, ammo. Emits `chosen` on click and
## `hovered` when the mouse enters or leaves; the hand fan moves it with `go_to`.

signal chosen(uid: int)
signal hovered(uid: int, on: bool)

const SIZE := Vector2(200, 290)
const TYPE_COLORS: Dictionary[StringName, Color] = {
	&"attack": Color("8a1c1c"), &"support": Color("4d5a6a"), &"consumable": Color("3f6a3a"),
	&"capture": Color("8a6a2a"), &"rage": Color("a0302a"), &"curse": Color("3a3340"),
}

var uid: int = 0
var card: CardInstance
var _glow: Panel
var _tween: Tween


func setup(instance: CardInstance) -> CardView:
	card = instance
	uid = instance.uid
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var def := instance.def
	var frame := CombatKit.image("card_frame__%s" % def.type, Vector2.ZERO, SIZE)
	if frame.texture == null:
		frame.texture = CombatKit.tex("card_frame__attack")
	add_child(frame)
	_add_glow()
	_add_art(def)
	_add_texts(def)
	add_child(CombatKit.image("cost_cog", Vector2(-10, -10), Vector2(58, 56)))
	add_child(CombatKit.outlined("%d" % def.cost if not def.unplayable else "—", 28, Palette.PARCHMENT, Vector2(-10, 0), 58.0))
	mouse_entered.connect(func() -> void: hovered.emit(uid, true))
	mouse_exited.connect(func() -> void: hovered.emit(uid, false))
	return self


func _add_glow() -> void:
	_glow = Panel.new()
	_glow.position = Vector2(-5, -5)
	_glow.size = SIZE + Vector2(10, 10)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = Palette.BRASS_LIGHT
	box.set_border_width_all(5)
	box.set_corner_radius_all(12)
	box.shadow_color = Color(0.9, 0.7, 0.3, 0.55)
	box.shadow_size = 14
	_glow.add_theme_stylebox_override("panel", box)
	_glow.visible = false
	add_child(_glow)


func _add_art(def: CardDef) -> void:
	var window := Rect2(20, 54, 160, 106)
	var art_path := "res://art/ui/CARD__art__%s.webp" % def.id
	var art := TextureRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.position = window.position
	art.size = window.size
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(art_path):
		art.texture = UiKit.texture(art_path)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:  # no engraving yet: the type icon, large and faded
		art.texture = Icons.texture("CARD_TYPE", def.type)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.modulate = Color(1, 1, 1, 0.3)
	add_child(art)
	var border := Panel.new()
	border.position = window.position
	border.size = window.size
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = TYPE_COLORS.get(def.type, Palette.BRASS)
	box.set_border_width_all(2)
	border.add_theme_stylebox_override("panel", box)
	add_child(border)


func _add_texts(def: CardDef) -> void:
	var title := UiKit.label(def.name, 18 if def.name.length() <= 13 else 14, Palette.SOOT)
	title.position = Vector2(46, 14)
	title.size = Vector2(140, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var kind := Loc.or_default("card_type.%s" % def.type, String(def.type).capitalize())
	var type_row := HBoxContainer.new()
	type_row.position = Vector2(22, 164)
	type_row.size = Vector2(156, 22)
	type_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_row.add_child(Icons.rect("CARD_TYPE", def.type, 20))
	type_row.add_child(UiKit.label(kind, 13, TYPE_COLORS.get(def.type, Palette.INK_MUTED)))
	add_child(type_row)
	var text := UiKit.paragraph(def.text, 14, Palette.SOOT)
	text.position = Vector2(22, 188)
	text.size = Vector2(156, 68)
	text.clip_text = true
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text)
	if def.ammo > 0:
		var ammo := HBoxContainer.new()
		ammo.position = Vector2(22, 260)
		ammo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i: int in def.ammo:
			ammo.add_child(Icons.rect("STAT", &"ammo", 20))
		add_child(ammo)


## Dims an unplayable card; `lit` = chosen for aiming (or a hint, like the reload card with an empty chamber).
func set_state(playable: bool, lit: bool) -> void:
	modulate = Color.WHITE if playable else Color(0.62, 0.62, 0.62)
	_glow.visible = lit


## Moves the card to a pose in the hand fan (position of the top-left corner, rotation in radians, scale).
func go_to(pos: Vector2, rot: float, factor: float, time: float = 0.16) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", pos, time)
	_tween.tween_property(self, "rotation", rot, time)
	_tween.tween_property(self, "scale", Vector2(factor, factor), time)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit(uid)
		accept_event()
