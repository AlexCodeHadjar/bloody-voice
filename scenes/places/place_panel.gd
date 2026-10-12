class_name PlacePanel
extends Control
## Base of a small full-screen panel for a place (infirmary, Scriptorium): a dimmed map, a framed box with an NPC
## portrait on the left and `body` on the right, a close cross; Esc closes. Subclasses fill `body` in _fill().

signal closed

var body: VBoxContainer
var message: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(980, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.045, 0.97), Palette.BRASS))
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	panel.add_child(h)
	h.add_child(UiKit.picture(UiKit.texture(_portrait()), Vector2(240, 240)))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	h.add_child(right)
	var head := HBoxContainer.new()
	var title := UiKit.label(_title(), 32, Palette.BRASS_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(44, 44)
	close.pressed.connect(close_panel)
	head.add_child(close)
	right.add_child(head)
	message = UiKit.paragraph("", 17, Palette.FOG)
	right.add_child(message)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	right.add_child(body)
	refill()
	UiKit.sound(&"ui.open")


func refill() -> void:
	for child: Node in body.get_children():
		child.queue_free()
	_fill()


## A finished day action: the outcome text and «Дальше».
func show_done(text: String) -> void:
	for child: Node in body.get_children():
		child.queue_free()
	message.text = ""
	body.add_child(UiKit.paragraph(text, 19, Palette.PARCHMENT))
	body.add_child(UiKit.label(Loc.t("ui.rumor.day_over"), 16, Palette.INK_MUTED))
	var next := UiKit.button(Loc.t("ui.rumor.next"), 20)
	next.pressed.connect(close_panel)
	body.add_child(next)


func close_panel() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()


func _portrait() -> String:
	return ""


func _title() -> String:
	return ""


func _fill() -> void:
	pass
