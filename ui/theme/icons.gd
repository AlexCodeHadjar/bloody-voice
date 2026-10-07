class_name Icons
extends RefCounted
## Game icons (data/ui/icons.json, imported to art/ui/icons/<SET>__<id>.webp) and small icon widgets.

const DIR := "res://art/ui/icons/"


static func path(set_code: String, id: StringName) -> String:
	return "%s%s__%s.webp" % [DIR, set_code, id]


static func texture(set_code: String, id: StringName) -> Texture2D:
	return UiKit.texture(path(set_code, id))


## A square icon of `side` px; empty (but sized) when the art is missing, so layouts stay stable.
static func rect(set_code: String, id: StringName, side: float = 28.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture(set_code, id)
	r.custom_minimum_size = Vector2(side, side)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Icon followed by a label, e.g. a heart and "12".
static func with_text(set_code: String, id: StringName, text: String, side: float = 28.0,
		font_size: int = 18, color: Color = Palette.PARCHMENT) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(rect(set_code, id, side))
	var l := UiKit.label(text, font_size, color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	return h


## Fills `box` with block and status icons of a combatant (statuses show their stack count).
static func fill_statuses(box: HBoxContainer, c: Combatant) -> void:
	for child: Node in box.get_children():
		child.queue_free()
	if c.block > 0:
		box.add_child(_tip(with_text("STAT", &"block", str(c.block), 30, 18, Palette.FOG), "Block %d" % c.block))
	for s: StringName in c.statuses:
		var label := "%s %d" % [String(s).capitalize(), c.statuses[s]]
		box.add_child(_tip(with_text("STATUS", s, str(c.statuses[s]), 30, 18, Palette.FOG), label))


## Button with an icon on the left of its text.
static func button(set_code: String, id: StringName, text: String, font_size: int = 22) -> Button:
	var b := UiKit.button(text, font_size)
	b.icon = texture(set_code, id)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", font_size + 14)
	return b


static func _tip(c: Control, text: String) -> Control:
	c.tooltip_text = text
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c
