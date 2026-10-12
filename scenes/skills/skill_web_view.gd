class_name SkillWebView
extends Control
## One skill web drawn as a graph (GDD 23.2 zone 3): node pictures by type, links (bright when both ends are owned),
## owned nodes lit, buyable nodes pulsing in a gold ring, locked ones dark. Drag with the left button, wheel zoom.
## Knows no rules beyond reading the run: a click reports the node.

signal node_picked(node_id: StringName)

const SPACING := 170.0
const SIZES: Dictionary[StringName, float] = {&"start": 150.0, &"keystone": 116.0}
const NODE_SIZE := 92.0
const ZOOM_MIN := 0.45
const ZOOM_MAX := 1.4
const DRAG_THRESHOLD := 6.0
const RING := Color(0.95, 0.78, 0.35)
const LINK_OWNED := Color(0.85, 0.68, 0.38, 0.95)
const LINK_DARK := Color(0.4, 0.36, 0.3, 0.6)

var web: SkillDefs.WebDef
var art_prefix := "mech"  ## SKILLS__node_<prefix>__<type>
var selected: StringName = &""
var _canvas := Control.new()
var _buttons: Dictionary[StringName, TextureButton] = {}
var _zoom := 0.8
var _pressed := false
var _dragging := false
var _press := Vector2.ZERO
var _pulse := 0.0
var _states: Dictionary[StringName, StringName] = {}  ## node -> owned / available / locked, cached in refresh()


func setup(web_def: SkillDefs.WebDef, prefix: String) -> void:
	web = web_def
	art_prefix = prefix
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	for id: StringName in web.order:
		_canvas.add_child(_node_button(web.node(id)))
	resized.connect(center)
	refresh()


func center() -> void:
	_canvas.scale = Vector2.ONE * _zoom
	_canvas.position = size * 0.5
	queue_redraw()


func refresh() -> void:
	for id: StringName in _buttons:
		_states[id] = _state(id)
		_buttons[id].modulate = Color.WHITE if _states[id] != &"locked" else Color(0.38, 0.36, 0.34)
	queue_redraw()


func _node_button(nd: SkillDefs.NodeDef) -> TextureButton:
	var b := TextureButton.new()
	var side: float = SIZES.get(nd.type, NODE_SIZE)
	var path := "res://art/ui/SKILLS__start_%s.webp" % ("mechanic" if art_prefix == "mech" else "monster")
	if nd.type != &"start":
		path = "res://art/ui/SKILLS__node_%s__%s.webp" % [art_prefix, nd.type]
	b.texture_normal = UiKit.texture(path)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.size = Vector2(side, side)
	b.position = nd.pos * SPACING - b.size * 0.5
	b.tooltip_text = nd.name
	b.pressed.connect(func() -> void:
		if not _dragging:
			selected = nd.id
			node_picked.emit(nd.id)
			queue_redraw())
	_buttons[nd.id] = b
	return b


## owned / available / locked.
func _state(id: StringName) -> StringName:
	var run := GameState.run
	if SkillRules.is_owned(run, web, id):
		return &"owned"
	var nd := web.node(id)
	if nd.links.any(func(l: StringName) -> bool: return SkillRules.is_owned(run, web, l)):
		return &"available"
	return &"locked"


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta * 2.0, TAU)
	queue_redraw()  # the gold rings pulse; drawing reads the cached states only


func _draw() -> void:
	if web == null:
		return
	for id: StringName in web.order:
		var nd := web.node(id)
		for l: StringName in nd.links:
			var other := web.node(l)
			if other == null:
				continue
			var lit: bool = _states.get(id) == &"owned" and _states.get(l) == &"owned"
			draw_line(_screen(nd.pos), _screen(other.pos), LINK_OWNED if lit else LINK_DARK, 4.0 if lit else 2.0, true)
	for id: StringName in web.order:
		var nd := web.node(id)
		var r: float = SIZES.get(nd.type, NODE_SIZE) * 0.5 * _zoom
		if _states.get(id) == &"available":
			draw_arc(_screen(nd.pos), r + 6.0 + 3.0 * sin(_pulse), 0.0, TAU, 48, RING, 3.0, true)
		if id == selected:
			draw_arc(_screen(nd.pos), r + 12.0, 0.0, TAU, 48, Palette.PARCHMENT, 2.0, true)


func _screen(grid: Vector2) -> Vector2:
	return _canvas.position + grid * SPACING * _canvas.scale


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, _zoom * 1.1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, _zoom / 1.1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			_pressed = mb.pressed
			_press = mb.position
			if mb.pressed:
				_dragging = false
	var mm := event as InputEventMouseMotion
	if mm != null and _pressed:
		if mm.position.distance_to(_press) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			_canvas.position += mm.relative
			queue_redraw()


func _zoom_at(at: Vector2, z: float) -> void:
	var old := _zoom
	_zoom = clampf(z, ZOOM_MIN, ZOOM_MAX)
	_canvas.position = at - (at - _canvas.position) * (_zoom / old)
	_canvas.scale = Vector2.ONE * _zoom
	queue_redraw()
