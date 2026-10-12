class_name IntentView
extends Control
## One planned move of the creature as a brass medallion: intent icon and a big number; hover shows the full text (GDD 21.2).

const NUMBER_COLORS: Dictionary[StringName, Color] = {
	&"attack": Color("f2b3a8"), &"defend": Color("c6d0dc"), &"fear": Color("cdb6ee"),
	&"debuff": Color("ecd98a"), &"buff": Color("f0b88a"), &"heal": Color("a9d8a2"),
}


## The big number of a move: damage (x hits), else Sanity loss, else block, else heal; "" when it has none.
static func number_of(move: MonsterDef.MoveDef, enemy: EnemyCombatant, hero: HeroCombatant, b: BalanceDef) -> String:
	for op: StringName in [&"damage", &"sanity", &"block", &"heal"]:
		for e: Dictionary in move.effects:
			if StringName(str(e["op"])) != op:
				continue
			var amount := int(e["amount"])
			if op == &"damage":
				amount = DamageRules.compute(amount, enemy, hero, b)
			var hits := int(e.get("hits", 1))
			return str(amount) if hits <= 1 else "%d×%d" % [amount, hits]
	return ""


## upcoming = a foresight intent for the next turn: smaller and paler.
func setup(move: MonsterDef.MoveDef, number: String, cancelled: bool, upcoming: bool = false) -> void:
	var side := 66.0 if upcoming else 98.0
	custom_minimum_size = Vector2(side, side)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate = Color(1, 1, 1, 0.45) if cancelled or upcoming else Color.WHITE
	var kind := Loc.or_default("intent.%s" % move.kind, String(move.kind).capitalize())
	var head := Loc.t("ui.combat.intent_next", {"move": move.name}) if upcoming else move.name
	tooltip_text = "%s%s\n%s\n%s" % [head, "  " + Loc.t("ui.combat.cancelled") if cancelled else "", kind, move.text]
	add_child(CombatKit.image("intent_medallion", Vector2.ZERO, custom_minimum_size))
	var icon := Icons.rect("INTENT", move.kind, side * 0.38)
	icon.position = Vector2(side * 0.31, side * 0.12)
	add_child(icon)
	if number != "":
		var color: Color = NUMBER_COLORS.get(move.kind, Palette.PARCHMENT)
		var font_size := int(side * (0.27 if number.length() > 3 else 0.34))
		add_child(CombatKit.outlined(number, font_size, color, Vector2(0, side * 0.5), side))
