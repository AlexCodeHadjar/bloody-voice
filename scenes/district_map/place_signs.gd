class_name PlaceSigns
extends RefCounted
## Hanging signboards over the places where the hunter can do something (owner 2026-10-14): a small wrought plate
## with the action's icon over the building, always shown; under the mouse it grows a little, glows brass and shows
## the place's name. Drawn by DistrictOverlay in art pixels. "locked" and "soon" places get no sign.

const ICONS := {  ## landmark action -> [icon set, icon id]
	&"rest": ["PLACE", &"home"], &"workshop": ["ACTION", &"workshop"], &"rumors": ["PLACE", &"leaflets"],
	&"tavern": ["ACTION", &"tavern"], &"shop": ["PLACE", &"shop"], &"infirmary": ["PLACE", &"infirmary"],
	&"library": ["ACTION", &"library"],
}
const SIDE := 76.0  ## plate size, art px
const LIFT := 70.0  ## how far above the landmark centre the plate hangs
const PLATE := Color(0.13, 0.09, 0.07, 0.92)
const RIM := Color(0.72, 0.56, 0.3)
const RIM_HOT := Color(1.0, 0.83, 0.5)
const NAME_SIZE := 34


static func has_sign(lm: DistrictMapDef.LandmarkDef) -> bool:
	return ICONS.has(lm.action)


static func draw_all(canvas: CanvasItem, map: DistrictMapDef, hovered: DistrictMapDef.LandmarkDef, font: Font) -> void:
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		if has_sign(lm):
			_draw_one(canvas, lm, lm == hovered, font)


static func _draw_one(canvas: CanvasItem, lm: DistrictMapDef.LandmarkDef, hot: bool, font: Font) -> void:
	var side := SIDE * (1.18 if hot else 1.0)
	var top := lm.pos + Vector2(0.0, -LIFT - side)
	var rim := RIM_HOT if hot else RIM
	canvas.draw_line(top + Vector2(-side * 0.3, 0), top + Vector2(-side * 0.18, -18), rim, 3.0)  # the two chains
	canvas.draw_line(top + Vector2(side * 0.3, 0), top + Vector2(side * 0.18, -18), rim, 3.0)
	canvas.draw_line(top + Vector2(-side * 0.32, -18), top + Vector2(side * 0.32, -18), rim, 5.0)  # the bracket
	var plate := Rect2(top - Vector2(side * 0.5, 0.0), Vector2(side, side))
	if hot:
		canvas.draw_rect(plate.grow(10.0), Color(RIM_HOT, 0.18))
	canvas.draw_rect(plate, PLATE)
	canvas.draw_rect(plate, rim, false, 4.0)
	var pair: Array = ICONS[lm.action]
	var tex := Icons.texture(pair[0] as String, pair[1] as StringName)
	if tex != null:
		canvas.draw_texture_rect(tex, plate.grow(-side * 0.14), false)
	if hot:
		var w := font.get_string_size(lm.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		var at := Vector2(lm.pos.x - w * 0.5, plate.end.y + NAME_SIZE + 6.0)
		canvas.draw_string_outline(font, at, lm.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, 8, Color(0, 0, 0, 0.9))
		canvas.draw_string(font, at, lm.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, RIM_HOT)
