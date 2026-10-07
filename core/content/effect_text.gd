class_name EffectText
extends RefCounted
## Human-readable text built from effect ops, so a move's text can never disagree with its numbers.

const HITS_WORDS: Dictionary[int, String] = {1: "", 2: " twice", 3: " three times"}


## "Deal 4 twice, Bleed 2." from a list of effects. card_names: card id -> display name (for add_card).
static func describe(effects: Array[Dictionary], card_names: Dictionary = {}) -> String:
	var parts: PackedStringArray = []
	for e: Dictionary in effects:
		var t := _one(e, card_names)
		if t != "":
			parts.append(t)
	if parts.is_empty():
		return "Does nothing."
	var text := ", ".join(parts)
	return text.substr(0, 1).to_upper() + text.substr(1) + "."


static func _one(e: Dictionary, card_names: Dictionary) -> String:
	var amount := int(e.get("amount", 0))
	match StringName(str(e.get("op", ""))):
		&"damage":
			var hits := int(e.get("hits", 1))
			return "deal %d%s" % [amount, HITS_WORDS.get(hits, " %d times" % hits)]
		&"block":
			return "block %d" % amount
		&"heal":
			return "heal %d" % amount
		&"lose_hp":
			return "lose %d HP" % amount
		&"sanity":
			return "%d Sanity damage" % amount
		&"draw":
			return "draw %d" % amount
		&"gain_ap":
			return "gain %d AP" % amount
		&"reload":
			return "reload"
		&"foresight":
			return "see the next moves"
		&"apply_status":
			var who := " (self)" if str(e.get("to", "target")) == "self" else ""
			return "%s %d%s" % [str(e["status"]).capitalize(), int(e["stacks"]), who]
		&"add_card":
			var id := str(e["card"])
			return "adds %s" % card_names.get(StringName(id), id.capitalize())
		&"capture":
			return "try to capture"
	return ""
