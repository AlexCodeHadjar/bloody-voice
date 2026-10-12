class_name UiKit
extends RefCounted
## Small factory for themed UI pieces so screens stay short and consistent.

## Bundled OFL fonts (owner, 2026-10-12; licences next to them): text PT Serif, headings Old Standard TT.
const TEXT_FONT := "res://ui/fonts/PT_Serif-Web-Regular.ttf"
const HEADING_FONT := "res://ui/fonts/OldStandard-Regular.ttf"
const HEADING_SIZE := 28  ## labels this big or bigger use the heading font

static var _theme: Theme = null


static func theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


static func serif() -> Font:
	return load(TEXT_FONT) as Font


static func heading_font() -> Font:
	return load(HEADING_FONT) as Font


static func label(text: String, size: int = 20, color: Color = Palette.PARCHMENT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if size >= HEADING_SIZE:
		l.add_theme_font_override("font", heading_font())
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
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			sound(&"ui.hover"))
	b.pressed.connect(func() -> void: sound(&"ui.click"))
	return b


## Plays a sound through the Sound autoload (GDD 24); silent when it is not running (tests, tools).
static func sound(id: StringName) -> void:
	var s := _sound_service()
	if s != null:
		s.call("play", id)


## Music and ambience of a screen (data/audio/sounds.json/screens).
static func screen_sound(screen_id: StringName) -> void:
	var s := _sound_service()
	if s != null:
		s.call("screen", screen_id)


## The second ambience layer of the zone under the camera ("" = none).
static func zone_sound(ambience_id: StringName) -> void:
	var s := _sound_service()
	if s != null:
		s.call("zone", ambience_id)


## A creature's own voice (select / attack / hit / idle / phase2).
static func monster_sound(monster: StringName, event: StringName) -> void:
	var s := _sound_service()
	if s != null:
		s.call("play_monster", monster, event)


static func _sound_service() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(^"Sound") if tree != null else null


static func panel_box(fill: Color = Palette.PANEL, border: Color = Palette.BRASS) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(14)
	return s


## A picture of `size` that keeps its aspect and lets the mouse through.
static func picture(tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


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
