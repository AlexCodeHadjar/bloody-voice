class_name TutorialOverlay
extends CanvasLayer
## The hint on screen (GDD 22.1): 70 % veil with a lit cut-out around the explained element, a pulsing brass frame,
## a parchment bubble (title, 1–3 sentences, «2 / 9») with «Далее» / «Пропустить обучение»; on a «do» step «Далее»
## is hidden and «Пропустить шаг» appears after SKIP_DELAY. Clicks outside the cut-out are blocked.

signal next_pressed
signal skip_step_pressed
signal skip_all_pressed

const MARGIN := 12.0
const SKIP_DELAY := 20.0
const BUBBLE_WIDTH := 600.0
const CONTENT_MARGIN := 58.0  ## inside the ornate brass frame of the bubble art
const BUBBLE_ART := "res://art/ui/TUTORIAL__bubble.webp"

var _veil: TutorialVeil
var _bubble: PanelContainer
var _title: Label
var _text: Label
var _counter: Label
var _next: Button
var _skip_step: Button
var _anchor: StringName = &""
var _do_time := 0.0


func _ready() -> void:
	layer = 50
	_veil = TutorialVeil.new()
	add_child(_veil)
	_build_bubble()
	hide_hint()


func show_step(title: String, text: String, counter: String, anchor: StringName, waits_for_action: bool) -> void:
	_anchor = anchor
	_title.text = title
	_text.text = text
	_counter.text = counter
	_next.visible = not waits_for_action
	_skip_step.visible = false
	_do_time = SKIP_DELAY if waits_for_action else 0.0
	visible = true
	_veil.set_process(true)
	_bubble.size = Vector2.ZERO  # shrink to the new text
	_place()


func hide_hint() -> void:
	visible = false
	_veil.hole = Rect2()
	_veil.set_process(false)


func _process(delta: float) -> void:
	if not visible:
		return
	if _do_time > 0.0:
		_do_time -= delta
		_skip_step.visible = _do_time <= 0.0
	_place()


## Follows the anchor every frame and keeps the bubble beside the cut-out, never over it.
func _place() -> void:
	var r := TutorialAnchors.rect(_anchor)
	_veil.hole = r.grow(MARGIN) if r.has_area() else Rect2()
	var screen := _veil.get_viewport_rect().size
	var size := _bubble.get_combined_minimum_size()
	var pos := Vector2((screen.x - size.x) / 2.0, (screen.y - size.y) / 2.0)
	if _veil.hole.has_area():
		var h := _veil.hole
		pos.x = clampf(h.get_center().x - size.x / 2.0, 16.0, screen.x - size.x - 16.0)
		if h.end.y + size.y + 24.0 < screen.y:
			pos.y = h.end.y + 16.0
		elif h.position.y - size.y - 24.0 > 0.0:
			pos.y = h.position.y - size.y - 16.0
		else:
			pos = Vector2(h.end.x + 16.0 if h.end.x + size.x + 16.0 < screen.x else h.position.x - size.x - 16.0,
				clampf(h.position.y, 16.0, screen.y - size.y - 16.0))
	_bubble.position = pos


func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.theme = UiKit.theme()
	_bubble.custom_minimum_size = Vector2(BUBBLE_WIDTH, 0)
	_bubble.add_theme_stylebox_override("panel", _bubble_style())
	add_child(_bubble)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_bubble.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_title = UiKit.label("", 26, Palette.BLOOD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_counter = UiKit.label("", 16, Palette.INK_MUTED)
	head.add_child(_counter)
	_text = UiKit.paragraph("", 19, Palette.SOOT)
	_text.custom_minimum_size = Vector2(BUBBLE_WIDTH - 2.0 * CONTENT_MARGIN, 0)  # autowrap needs a width
	v.add_child(_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	_next = _small_button(Loc.t("ui.tutorial.next"), next_pressed)
	row.add_child(_next)
	_skip_step = _small_button(Loc.t("ui.tutorial.skip_step"), skip_step_pressed)
	row.add_child(_skip_step)
	row.add_child(_small_button(Loc.t("ui.tutorial.skip_all"), skip_all_pressed))


func _small_button(text: String, sig: Signal) -> Button:
	var b := UiKit.button(text, 17)
	b.custom_minimum_size = Vector2(150, 40)
	b.pressed.connect(func() -> void: sig.emit())
	return b


func _bubble_style() -> StyleBox:
	var tex := UiKit.texture(BUBBLE_ART)
	if tex == null:
		return UiKit.panel_box(Palette.PARCHMENT, Palette.BRASS)
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.set_texture_margin_all(64.0)
	s.set_content_margin_all(CONTENT_MARGIN)
	return s


## The 70 % veil with a rectangular cut-out and a pulsing brass frame; lets clicks through the cut-out only.
class TutorialVeil:
	extends Control

	var hole := Rect2()
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		size = get_viewport_rect().size  # a Control under a CanvasLayer has no parent rect to fill
		queue_redraw()

	func _has_point(point: Vector2) -> bool:
		return not hole.has_point(point)

	func _draw() -> void:
		var full := Rect2(Vector2.ZERO, size)
		var dim := Color(0, 0, 0, 0.7)
		if not hole.has_area():
			draw_rect(full, dim)
			return
		draw_rect(Rect2(0, 0, size.x, hole.position.y), dim)
		draw_rect(Rect2(0, hole.end.y, size.x, size.y - hole.end.y), dim)
		draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), dim)
		draw_rect(Rect2(hole.end.x, hole.position.y, size.x - hole.end.x, hole.size.y), dim)
		var pulse := 0.8 + 0.2 * sin(_t * TAU / 1.2)
		draw_rect(hole, Color(Palette.BRASS, pulse), false, 3.0)
