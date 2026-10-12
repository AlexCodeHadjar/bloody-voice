class_name NewsPanel
extends PlacePanel
## «Новости» (GDD 15): the morning leaflet of a district event starting or ending — its picture (EVENT__art__<id>),
## the news and what the state changes while it lasts. GameState.read_news is called when it closes (DistrictPanels).

const ART := "res://art/ui/SCREEN__register_leaflet.webp"

var news := ""  ## "<event>:start" / "<event>:end"


func _portrait() -> String:
	return ART


func _title() -> String:
	var e := ContentDB.data.event(StringName(news.get_slice(":", 0)))
	return Loc.t("ui.event.title", {"name": e.name if e != null else ""})


func _fill() -> void:
	var data := ContentDB.data
	var e := data.event(StringName(news.get_slice(":", 0)))
	if e == null:
		return
	var starting := news.ends_with(":start")
	body.add_child(UiKit.picture(UiKit.texture("res://art/ui/EVENT__art__%s.webp" % e.id), Vector2(0, 260)))
	body.add_child(UiKit.paragraph(e.news if starting else e.end_news, 19, Palette.PARCHMENT))
	if starting:
		body.add_child(UiKit.paragraph(effects_text(data.district_states.get(e.state) as DistrictStateDef, data), 16, Palette.BRASS))
	var next := UiKit.button(Loc.t("ui.rumor.next"), 20)
	next.pressed.connect(close_panel)
	body.add_child(next)


## What a state changes, in words (no numbers in the texts: they come from district_states.json and balance.json).
static func effects_text(def: DistrictStateDef, data: ContentData) -> String:
	if def == null:
		return ""
	var lines: PackedStringArray = []
	if def.danger_delta > 0:
		lines.append(Loc.t("ui.event.effect.danger", {"hp": _pct(pow(data.balance.events.danger_hp_mult, def.danger_delta)),
			"n": data.balance.events.danger_damage * def.danger_delta}))
	for pair: Array in [["shop", def.shop_price_mult], ["infirmary", def.infirmary_mult], ["shift", def.shift_pay_mult],
			["rewards", def.contract_reward_mult]]:
		if not is_equal_approx(pair[1] as float, 1.0):
			lines.append(Loc.t("ui.event.effect.%s" % pair[0], {"v": _pct(pair[1] as float)}))
	if def.rumor_bonus > 0:
		lines.append(Loc.t("ui.event.effect.rumors", {"n": def.rumor_bonus}))
	var closed: PackedStringArray = []
	for a: StringName in def.closed_actions:
		closed.append(Loc.t("ui.district.action.%s" % a))
	if not closed.is_empty():
		lines.append(Loc.t("ui.event.effect.closed", {"list": ", ".join(closed)}))
	return "\n".join(lines)


static func _pct(mult: float) -> String:
	var n := roundi((mult - 1.0) * 100.0)
	return ("+" if n > 0 else "") + str(n) + " %"
