class_name SettingsPanel
extends Control
## Settings over any screen (owner, 2026-10-12): volumes, tutorial hints, reset tutorial, full screen.
## From the main menu, or by Esc in the game (then it also offers «В главное меню»). Changes go to the Profile.

signal closed

const MENU := "res://scenes/menu/main_menu.tscn"

var _in_game := false
var _note: Label


## Opens above everything, tutorial hints included (their veil is layer 50).
static func open(parent: Node, in_game: bool) -> SettingsPanel:
	var layer := CanvasLayer.new()
	layer.layer = 60
	parent.add_child(layer)
	var p := SettingsPanel.new()
	p._in_game = in_game
	p.theme = UiKit.theme()
	layer.add_child(p)
	return p


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(560, 0)
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UiKit.label(Loc.t("ui.settings.title"), 36, Palette.BRASS_LIGHT))
	var p := Profile.state
	v.add_child(_slider(Loc.t("ui.settings.master"), p.volume_master, &"master"))
	v.add_child(_slider(Loc.t("ui.settings.music"), p.volume_music, &"music"))
	v.add_child(_slider(Loc.t("ui.settings.sounds"), p.volume_sounds, &"sounds"))
	v.add_child(_check(Loc.t("ui.settings.hints"), p.hints_on, Profile.set_hints))
	v.add_child(_check(Loc.t("ui.settings.fullscreen"), p.fullscreen, Profile.set_fullscreen))
	var reset := UiKit.button(Loc.t("ui.settings.reset_tutorial"), 18)
	reset.pressed.connect(_reset_tutorial)
	v.add_child(reset)
	_note = UiKit.label("", 16, Palette.FOG)
	v.add_child(_note)
	var close := UiKit.button(Loc.t("ui.settings.close"), 20)
	close.pressed.connect(_close)
	v.add_child(close)
	if _in_game:
		var menu := UiKit.button(Loc.t("ui.settings.to_menu"), 20)
		menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU))
		v.add_child(menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _slider(caption: String, value: float, which: StringName) -> Control:
	var row := HBoxContainer.new()
	var l := UiKit.label(caption, 18)
	l.custom_minimum_size = Vector2(240, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.value = value * 100.0
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(x: float) -> void: Profile.set_volume(which, x / 100.0, false))
	s.drag_ended.connect(func(_changed: bool) -> void: Profile.save())
	row.add_child(s)
	return row


func _check(caption: String, on: bool, setter: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = caption
	c.button_pressed = on
	c.add_theme_font_size_override("font_size", 18)
	c.toggled.connect(func(x: bool) -> void:
		setter.call(x)
		UiKit.sound(&"ui.click"))
	return c


func _reset_tutorial() -> void:
	Profile.reset_tutorial()
	_note.text = Loc.t("ui.settings.reset_done")


func _close() -> void:
	Profile.save()
	closed.emit()
	get_parent().queue_free()  # the CanvasLayer made by open()
