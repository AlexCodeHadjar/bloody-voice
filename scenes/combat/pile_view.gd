class_name PileView
extends Control
## A pile of cards in a corner (draw, discard, exhaust): the card back with a count; a click asks for the list (GDD 21.2).

signal clicked(pile: StringName)

const SIZE := Vector2(84, 130)

var pile: StringName
var _count: Label
var _back: TextureRect


func _init(pile_id: StringName = &"", tint: Color = Color.WHITE) -> void:
	pile = pile_id
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_back = CombatKit.image("card_back", Vector2.ZERO, SIZE)
	_back.modulate = tint
	add_child(_back)
	_count = CombatKit.outlined("0", 34, Palette.PARCHMENT, Vector2(0, SIZE.y / 2.0 - 24.0), SIZE.x)
	add_child(_count)
	add_child(CombatKit.outlined(Loc.t("ui.combat.pile.%s" % pile_id), 14, Palette.FOG, Vector2(-20, -22), SIZE.x + 40.0))
	tooltip_text = Loc.t("ui.combat.pile.%s" % pile_id)


func set_count(n: int) -> void:
	_count.text = str(n)
	_back.modulate.a = 1.0 if n > 0 else 0.4


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(pile)
		accept_event()
