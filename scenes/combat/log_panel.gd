class_name LogPanel
extends Control
## The fight log: a «Журнал» tab on the right edge that unrolls a parchment scroll (GDD 21.2 zone 6).

const SCROLL_SIZE := Vector2(350, 694)
const LINES := 16

var _scroll: Control
var _text: Label
var _open := false
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll = Control.new()
	_scroll.position = Vector2(-SCROLL_SIZE.x - 130.0, -240)
	_scroll.size = SCROLL_SIZE
	_scroll.modulate.a = 0.0
	_scroll.visible = false
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scroll)
	_scroll.add_child(CombatKit.image("log_scroll", Vector2.ZERO, SCROLL_SIZE))
	_text = UiKit.paragraph("", 15, Palette.SOOT)
	_text.position = Vector2(48, 96)
	_text.size = Vector2(SCROLL_SIZE.x - 96.0, SCROLL_SIZE.y - 190.0)
	_text.clip_text = true
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(_text)
	var tab := Button.new()
	tab.text = Loc.t("ui.combat.log")
	tab.add_theme_font_size_override("font_size", 20)
	tab.position = Vector2(-124, 0)
	tab.size = Vector2(124, 46)
	tab.focus_mode = Control.FOCUS_NONE
	tab.pressed.connect(toggle)
	add_child(tab)


func refresh(s: CombatState) -> void:
	var lines: PackedStringArray = []
	for i: int in range(maxi(0, s.events.size() - LINES), s.events.size()):
		lines.append(s.events[i].text)
	_text.text = "\n".join(lines)


func is_open() -> bool:
	return _open


func toggle() -> void:
	set_open(not _open)


func set_open(on: bool) -> void:
	_open = on
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	if on:
		_scroll.visible = true
		_tween.tween_property(_scroll, "modulate:a", 1.0, 0.18)
	else:
		_tween.tween_property(_scroll, "modulate:a", 0.0, 0.14)
		_tween.tween_callback(func() -> void: _scroll.visible = false)
