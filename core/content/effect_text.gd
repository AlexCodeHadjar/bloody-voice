class_name EffectText
extends RefCounted
## Human-readable text built from effect ops, so a move's text can never disagree with its numbers.
## Phrases are templates in locale/strings.csv (effect.*), with Russian plural forms (GDD 22.5).


## "Урон 4 дважды, кровотечение 2." from a list of effects. card_names: card id -> shown name (for add_card).
static func describe(effects: Array[Dictionary], card_names: Dictionary = {}) -> String:
	var parts: PackedStringArray = []
	for e: Dictionary in effects:
		var t := _one(e, card_names)
		if t != "":
			parts.append(t)
	if parts.is_empty():
		return Loc.t("effect.none")
	var text := ", ".join(parts)
	return text.substr(0, 1).to_upper() + text.substr(1) + "."


static func status_name(status: StringName) -> String:
	return Loc.or_default("status.%s.name" % status, String(status).capitalize())


static func _one(e: Dictionary, card_names: Dictionary) -> String:
	var n := int(e.get("amount", 0))
	var op := StringName(str(e.get("op", "")))
	match op:
		&"damage":
			var hits := int(e.get("hits", 1))
			return Loc.t("effect.damage", {"n": n}) + _hits(hits)
		&"block", &"heal", &"lose_hp", &"sanity", &"draw", &"gain_ap", &"reload", &"foresight", &"capture":
			return Loc.t("effect.%s" % op, {"n": n})
		&"apply_status":
			var key := "effect.status_self" if str(e.get("to", "target")) == "self" else "effect.status"
			return Loc.t(key, {"status": status_name(StringName(str(e["status"]))).to_lower(), "n": int(e["stacks"])})
		&"add_card":
			var id := StringName(str(e["card"]))
			var shown: String = card_names.get(id, Loc.or_default("card.%s.name" % id, String(id).capitalize()))
			return Loc.t("effect.add_card", {"card": shown})
	return ""


static func _hits(hits: int) -> String:
	if hits <= 1:
		return ""
	return " " + (Loc.t("effect.hits", {"h": hits}) if hits > 3 else Loc.t("effect.hits_%d" % hits))
