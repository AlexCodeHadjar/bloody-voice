class_name PlaceSigns
extends RefCounted
## Hanging signboards over the places where the hunter can do something (owner 2026-10-14): the drawn wrought sign of
## the place (art/ui/SIGN__*.webp, owner 2026-10-14) over the building, always shown; under the mouse it grows a
## little, brightens and shows the place's name. A place without its art gets a small plate with the action's icon.
## Drawn by DistrictOverlay in art pixels. "locked" and "soon" places get no sign.

const ICONS := {  ## landmark action -> [icon set, icon id]
	&"rest": ["PLACE", &"home"], &"workshop": ["ACTION", &"workshop"],
	&"tavern": ["ACTION", &"tavern"], &"shop": ["PLACE", &"shop"], &"infirmary": ["PLACE", &"infirmary"],
	&"library": ["ACTION", &"library"],
}
const ART := {  ## landmark action -> signboard art id
	&"rest": &"home", &"workshop": &"workshop", &"tavern": &"tavern", &"shop": &"shop", &"infirmary": &"infirmary",
	&"library": &"library",
}
const ART_PATH := "res://art/ui/SIGN__%s.webp"
const ART_WIDTH := 150.0  ## the drawn sign with its bracket, art px
const SIDE := 76.0  ## plate size, art px
const LIFT := 70.0  ## how far above the landmark centre the plate hangs
const PLATE := Color(0.13, 0.09, 0.07, 0.92)
const RIM := Color(0.72, 0.56, 0.3)
const RIM_HOT := Color(1.0, 0.83, 0.5)
const NAME_SIZE := 34

static var _art: Dictionary[StringName, Texture2D] = {}  ## action -> signboard art (null = none); kept like _textures
static var _textures: Dictionary[StringName, Texture2D] = {}  ## kept here: a texture nobody holds is freed before the frame is drawn (white squares)


static func has_sign(lm: DistrictMapDef.LandmarkDef) -> bool:
	return ICONS.has(lm.action)


static func draw_all(canvas: CanvasItem, map: DistrictMapDef, hovered: DistrictMapDef.LandmarkDef, font: Font) -> void:
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		if has_sign(lm):
			_draw_one(canvas, lm, lm == hovered, font)


static func _draw_one(canvas: CanvasItem, lm: DistrictMapDef.LandmarkDef, hot: bool, font: Font) -> void:
	var art := _sign_art(lm.action)
	var bottom := _draw_art(canvas, lm, art, hot) if art != null else _draw_plate(canvas, lm, hot)
	if hot:
		var w := font.get_string_size(lm.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		var at := Vector2(lm.pos.x - w * 0.5, bottom + NAME_SIZE + 6.0)
		canvas.draw_string_outline(font, at, lm.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, 8, Color(0, 0, 0, 0.9))
		canvas.draw_string(font, at, lm.name, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE, RIM_HOT)


## The drawn signboard hanging over the place; returns its bottom edge (y).
static func _draw_art(canvas: CanvasItem, lm: DistrictMapDef.LandmarkDef, tex: Texture2D, hot: bool) -> float:
	var w := ART_WIDTH * (1.12 if hot else 1.0)
	var size := Vector2(w, w * tex.get_size().y / tex.get_size().x)
	var rect := Rect2(Vector2(lm.pos.x - size.x * 0.5, lm.pos.y - LIFT + 10.0 - size.y), size)
	if hot:
		canvas.draw_circle(rect.get_center(), size.x * 0.45, Color(RIM_HOT, 0.16))  # a warm glow behind it
	canvas.draw_texture_rect(tex, rect, false, Color(1.25, 1.15, 1.0) if hot else Color.WHITE)
	return rect.end.y


## The fallback: a small plate with the action's icon; returns its bottom edge (y).
static func _draw_plate(canvas: CanvasItem, lm: DistrictMapDef.LandmarkDef, hot: bool) -> float:
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
	var tex := _icon(lm.action)
	if tex != null:
		var box := plate.grow(-side * 0.14)
		var fit := tex.get_size() * minf(box.size.x / tex.get_size().x, box.size.y / tex.get_size().y)
		canvas.draw_texture_rect(tex, Rect2(box.get_center() - fit * 0.5, fit), false)  # keeps the icon's proportions
	return plate.end.y


static func _sign_art(action: StringName) -> Texture2D:
	if not _art.has(action):
		var path := ART_PATH % ART.get(action, &"")
		_art[action] = load(path) as Texture2D if ART.has(action) and ResourceLoader.exists(path) else null
	return _art[action]


static func _icon(action: StringName) -> Texture2D:
	if not _textures.has(action):
		var pair: Array = ICONS[action]
		_textures[action] = Icons.texture(pair[0] as String, pair[1] as StringName)
	return _textures[action]
