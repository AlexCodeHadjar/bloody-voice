class_name DeckFanView
extends Control
## The fight deck as a fan of real cards leaning on a ledge (owner 2026-10-14, sketch
## docs/assets/ui/equipment_workbench.png): the same card twice or more is one card with «×N»; the cards of the module
## under the mouse on the rifle are lit and rise; hovering a card raises it. Totals on the left.

const LEDGE_ART := "res://art/ui/EQUIP__deck_ledge.webp"
const FACTOR := 0.62  ## card scale
const STEP := 132.0  ## distance between cards
const LEFT := 330.0  ## where the fan starts (the totals are left of it)
const TILT := 0.045  ## radians per card away from the middle

var _cards: Array[CardView] = []
var _origins: Array[String] = []  ## where each shown card comes from (same index)
var _totals: Label
var _lit_origin := ""
var _hovered := -1


func setup() -> void:
	custom_minimum_size = Vector2(1872, 276)
	var ledge := TextureRect.new()
	ledge.texture = UiKit.texture(LEDGE_ART)
	ledge.position = Vector2(LEFT - 40, 214)
	ledge.size = Vector2(1872 - LEFT + 20, 60)
	ledge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ledge.stretch_mode = TextureRect.STRETCH_SCALE
	ledge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ledge)
	add_child(UiKit.label(Loc.t("ui.equip.deck"), 30, Palette.BRASS_LIGHT))
	_totals = UiKit.paragraph("", 18, Palette.PARCHMENT)
	_totals.position = Vector2(0, 48)
	_totals.size = Vector2(LEFT - 30, 220)
	add_child(_totals)


func refresh() -> void:
	for c: CardView in _cards:
		c.queue_free()
	_cards.clear()
	_origins.clear()
	var b := DeckBuilder.build(GameState.run.loadout, ContentDB.data)
	var counts: Dictionary[Array, int] = {}  ## [card id, origin] -> copies
	var order: Array[Array] = []
	for i: int in b.deck.size():
		var key: Array = [b.deck[i], b.origins[i]]
		if not counts.has(key):
			order.append(key)
		counts[key] = counts.get(key, 0) + 1
	for i: int in order.size():
		_add_card(i, ContentDB.data.card(order[i][0] as StringName), counts[order[i]], order[i][1] as String)
	_totals.text = _totals_text(b)
	_place()


func _add_card(i: int, def: CardDef, count: int, origin: String) -> void:
	var view := CardView.new().setup(CardInstance.create(i, def))
	view.tooltip_text = Loc.t("ui.equip.card_origin", {"origin": origin})
	view.hovered.connect(func(uid: int, on: bool) -> void:
		_hovered = uid if on else -1
		_place())
	if count > 1:
		var badge := UiKit.label("×%d" % count, 40, Palette.BRASS_LIGHT)
		badge.add_theme_constant_override("outline_size", 10)
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		badge.position = Vector2(CardView.SIZE.x - 78, CardView.SIZE.y - 66)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.add_child(badge)
	add_child(view)
	_cards.append(view)
	_origins.append(origin)


## Lights and raises the cards that come from `origin` (a module's name; "" = none).
func light(origin: String) -> void:
	_lit_origin = origin
	_place()


func _place() -> void:
	var mid := (_cards.size() - 1) * 0.5
	var room := custom_minimum_size.x - LEFT - CardView.SIZE.x * FACTOR
	var step := minf(STEP, room / maxf(1.0, _cards.size() - 1))  # many different cards overlap more
	for i: int in _cards.size():
		var lit := _lit_origin != "" and _origins[i] == _lit_origin
		var up := 40.0 if lit or i == _hovered else 0.0
		var pos := Vector2(LEFT + i * step, 30 + absf(i - mid) * 4.0 - up)
		_cards[i].z_index = 10 if i == _hovered else (5 if lit else 0)
		_cards[i].set_state(true, lit)
		_cards[i].go_to(pos, (i - mid) * TILT, 1.12 * FACTOR if i == _hovered else FACTOR)


func _totals_text(b: DeckBuilder.Build) -> String:
	var lines: PackedStringArray = [Loc.t("ui.equip.deck_total", {"cards": b.deck.size(), "ammo": b.max_ammo})]
	for k: StringName in b.mods:
		if k != &"max_ammo" and b.mods[k] != 0:  # a cost and a bonus of the same kind may cancel out
			lines.append("%s %s" % [Loc.t("mod.%s" % k), UiKit.signed(b.mods[k])])
	for link: String in b.links:
		lines.append(Loc.t("ui.equip.link", {"link": link}))
	return "\n".join(lines)
