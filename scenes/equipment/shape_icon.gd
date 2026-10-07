class_name ShapeIcon
extends Control
## Small picture of a module's cell shape (for the spare-module list).

const CELL := 13.0
const COLORS: Dictionary[StringName, Color] = {
	&"gear": Color("c9a35a"), &"spark": Color("5d8fd0"), &"blood": Color("b04040"),
}

var _cells: Array[Vector2i] = []
var _color: Color = Color.WHITE


func setup(cells: Array[Vector2i], cell_type: StringName) -> ShapeIcon:
	_cells = cells
	_color = COLORS.get(cell_type, Palette.BRASS)
	custom_minimum_size = Vector2(4 * CELL + 6, 4 * CELL + 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	for c: Vector2i in _cells:
		var r := Rect2(Vector2(3, 3) + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-1)
		draw_rect(r, _color)
		draw_rect(r, Palette.SOOT, false, 1.0)
