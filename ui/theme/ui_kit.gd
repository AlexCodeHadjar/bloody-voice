class_name UiKit
extends RefCounted
## Small factory for themed UI pieces so screens stay short and consistent.

const SERIF_FONTS: PackedStringArray = ["Georgia", "Palatino Linotype", "Book Antiqua", "Times New Roman", "serif"]

static var _theme: Theme = null


static func theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


static func serif() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = SERIF_FONTS
	return f


static func label(text: String, size: int = 20, color: Color = Palette.PARCHMENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func paragraph(text: String, size: int = 17, color: Color = Palette.FOG) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(260, 52)
	return b


static func panel_box(fill: Color = Palette.PANEL, border: Color = Palette.BRASS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(14)
	return s


static func texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = serif()
	t.default_font_size = 18
	var normal := panel_box(Color(0.16, 0.12, 0.09, 0.95), Palette.BRASS)
	var hover := panel_box(Color(0.26, 0.19, 0.12, 0.98), Palette.BRASS_LIGHT)
	var pressed := panel_box(Color(0.35, 0.10, 0.10, 1.0), Palette.BRASS_LIGHT)
	var disabled := panel_box(Color(0.12, 0.11, 0.10, 0.7), Palette.INK_MUTED)
	for pair: Array in [["normal", normal], ["hover", hover], ["pressed", pressed], ["disabled", disabled], ["focus", hover]]:
		t.set_stylebox(pair[0] as String, "Button", pair[1] as StyleBox)
	t.set_color("font_color", "Button", Palette.PARCHMENT)
	t.set_color("font_hover_color", "Button", Palette.BRASS_LIGHT)
	t.set_color("font_disabled_color", "Button", Palette.INK_MUTED)
	t.set_stylebox("panel", "PanelContainer", panel_box())
	return t
