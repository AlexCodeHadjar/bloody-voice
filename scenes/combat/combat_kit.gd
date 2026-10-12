class_name CombatKit
extends RefCounted
## Small helpers shared by the fight screen widgets: combat art, placing controls, floating numbers (GDD 21).

const ART := "res://art/ui/COMBAT__%s.webp"
const FONT_OUTLINE := Color(0.03, 0.02, 0.02, 0.95)


static func tex(art_name: String) -> Texture2D:
	return UiKit.texture(ART % art_name)


## A non-interactive picture placed at an absolute position (the parent is not a container).
static func image(art_name: String, pos: Vector2, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(art_name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = pos
	r.size = size
	return r


## A 9-slice plate. Godot draws patch margins unscaled, so the node is made bigger and scaled down to `size`.
static func plate(pos: Vector2, size: Vector2, margins: Vector4i = Vector4i(110, 70, 110, 70)) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex("plate")
	n.patch_margin_left = margins.x
	n.patch_margin_top = margins.y
	n.patch_margin_right = margins.z
	n.patch_margin_bottom = margins.w
	var k := size.x / 1156.0
	n.size = size / k
	n.scale = Vector2(k, k)
	n.position = pos
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return n


## A label with a dark outline, readable on any picture; placed by its top-left corner.
static func outlined(text: String, font_size: int, color: Color, pos: Vector2, width: float) -> Label:
	var l := UiKit.label(text, font_size, color)
	l.add_theme_color_override("font_outline_color", FONT_OUTLINE)
	l.add_theme_constant_override("outline_size", maxi(3, font_size / 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.size = Vector2(width, font_size * 1.4)
	return l


## Status icons (not block: it has its own badge) with their stack counts.
static func fill_statuses(box: Container, c: Combatant) -> void:
	for child: Node in box.get_children():
		child.queue_free()
	for s: StringName in c.statuses:
		var item := Icons.with_text("STATUS", s, str(c.statuses[s]), 28, 17, Palette.FOG)
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.tooltip_text = "%s %d" % [EffectText.status_name(s), c.statuses[s]]
		box.add_child(item)


## A number that rises from `at` (a position in `layer`) and fades out.
static func float_text(layer: Control, text: String, at: Vector2, color: Color, delay: float = 0.0) -> void:
	var l := outlined(text, 46, color, Vector2.ZERO, 0.0)
	l.size = l.get_minimum_size()
	l.position = at - l.size / 2.0
	l.modulate.a = 0.0
	layer.add_child(l)
	var t := l.create_tween()
	t.tween_interval(delay)
	t.tween_property(l, "modulate:a", 1.0, 0.06)
	t.tween_property(l, "position:y", l.position.y - 80.0, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.5)
	t.tween_callback(l.queue_free)
