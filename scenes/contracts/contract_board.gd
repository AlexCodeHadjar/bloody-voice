class_name ContractBoard
extends Control
## The contract board of the Lantern & Hook (GDD 7.1): the wooden wall with this week's leaflets. A click on a
## leaflet opens its tablet; taken leaflets carry the hunter's seal. New leaflets every Monday.
## Full-screen overlay over the district screen; closes with the cross or Esc.

signal closed

const ART := "res://art/ui/TAVERN__contract_board.webp"
const BOARD := Vector2(1560, 878)

var _row: HBoxContainer
var _tablet: ContractTablet = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(_build_board())
	EventBus.contracts_changed.connect(_fill)
	_fill()
	UiKit.sound(&"ui.open")
	TutorialAnchors.register(&"contract_board", _row)
	Tutorial.trigger.call_deferred(&"contract_board_open")


func _build_board() -> Control:
	var board := TextureRect.new()
	board.texture = UiKit.texture(ART)
	board.custom_minimum_size = BOARD
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 60
	v.offset_right = -60
	v.offset_top = 30
	v.offset_bottom = -40
	v.add_theme_constant_override("separation", 14)
	board.add_child(v)
	var title := UiKit.label(Loc.t("ui.contract.board_title"), 34, Palette.BRASS_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	v.add_child(title)
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 22)
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_row)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(48, 48)
	close.position = Vector2(BOARD.x - 70, 18)
	close.pressed.connect(close_board)
	board.add_child(close)
	return board


func _fill() -> void:
	for child: Node in _row.get_children():
		child.queue_free()
	var leaflets := ContractRules.board(GameState.run.contracts)
	if leaflets.is_empty():
		var empty := UiKit.label(Loc.t("ui.contract.board_empty"), 22, Palette.FOG)
		empty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_row.add_child(empty)
		return
	for i: int in leaflets.size():
		var leaflet := ContractLeaflet.new()
		leaflet.setup(leaflets[i])
		leaflet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		leaflet.pressed.connect(open_tablet.bind(leaflets, i))
		_row.add_child(leaflet)


func open_tablet(list: Array[ContractsState.Contract], index: int) -> void:
	if _tablet != null:
		return
	_tablet = ContractTablet.new()
	add_child(_tablet)
	_tablet.open_list(list, index)
	_tablet.closed.connect(func() -> void: _tablet = null)


func close_board() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _tablet == null and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_board()
