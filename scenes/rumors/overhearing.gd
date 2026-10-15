class_name Overhearing
extends Control
## Rumors overheard on the way (GDD 8.4, owner 2026-10-15): every overhear_steps footsteps of the walking hunter a roll;
## an overheard rumor shows a scrap of it over the hunter for a moment («…детское пение…»), then a paper leaflet flies
## from him into the notebook on the top bar. Nothing stays on the map. Lives over the screen, ignores the mouse.

const LEAFLET := "res://art/ui/RUMOR__leaflet.webp"
const PHRASE_TIME := 1.6
const FLY_TIME := 0.7

var _map: DistrictMapDef
var _hero: HeroWalker
var _bar: DistrictBar
var _busy: Callable
var _steps := 0


func setup(map: DistrictMapDef, hero: HeroWalker, bar: DistrictBar, busy: Callable) -> void:
	_map = map
	_hero = hero
	_bar = bar
	_busy = busy
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.stepped.connect(_on_step)


func _on_step() -> void:
	_steps += 1
	if _steps < ContentDB.data.balance.rumors.overhear_steps or _busy.call():
		return
	_steps = 0
	var card := GameState.overhear_rumor(DistrictMapRules.zone_at(_map, _hero.position))
	if card != null:
		_show(card)


## The scrap over the hunter, then the leaflet flying into the notebook.
func _show(card: RumorsState.Card) -> void:
	var at := _hero.get_global_transform_with_canvas().origin
	var phrase := UiKit.label("«…%s…»" % ContractKit.tag_name(card.tags[0]), 22, Palette.PARCHMENT)
	phrase.add_theme_constant_override("outline_size", 8)
	phrase.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_child(phrase)
	phrase.reset_size()
	phrase.position = at - Vector2(phrase.size.x * 0.5, 120.0)
	phrase.modulate.a = 0.0
	var tw := create_tween()  # on this node: the phrase frees itself mid-way
	tw.tween_property(phrase, "modulate:a", 1.0, 0.25)
	tw.tween_interval(PHRASE_TIME)
	tw.tween_property(phrase, "modulate:a", 0.0, 0.3)
	tw.tween_callback(phrase.queue_free)
	tw.tween_callback(_fly.bind(at - Vector2(0.0, 80.0)))
	UiKit.sound(&"paper.map")
	Tutorial.trigger.call_deferred(&"first_overheard")


func _fly(from: Vector2) -> void:
	var leaf := TextureRect.new()
	leaf.texture = UiKit.texture(LEAFLET)
	leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leaf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	leaf.size = Vector2(46, 62)
	leaf.pivot_offset = leaf.size * 0.5
	leaf.position = from - leaf.size * 0.5
	leaf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leaf)
	var to := _bar.notebook_center() - get_global_rect().position - leaf.size * 0.5
	var tw := leaf.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(leaf, "position", to, FLY_TIME)
	tw.tween_property(leaf, "rotation", 0.6, FLY_TIME)
	tw.tween_property(leaf, "scale", Vector2.ONE * 0.5, FLY_TIME)
	tw.chain().tween_callback(leaf.queue_free)
