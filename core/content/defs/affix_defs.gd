class_name AffixDefs
extends RefCounted
## Creature affixes (GDD 17 MonsterVariant): data/affixes/affixes.json and the "affixes" block of balance.json.


class AffixDef:
	var id: StringName
	var name: String
	var weight: float = 1.0
	var hp_mult: float = 1.0
	var tag: StringName  ## the sign it adds (contracts/tags.json)
	var move: MonsterDef.MoveDef  ## put into the creature's deck


class Balance:
	var per_week: float = 0.0  ## threat per week after the first
	var per_rank: float = 0.0  ## threat per Register rank above A
	var max_affixes: int = 2


static func affix(d: Dictionary, errs: ErrorLog) -> AffixDef:
	var a := AffixDef.new()
	a.id = DefReader.id(d, "id", errs, "affixes/affixes.json")
	var w := "affixes/affixes.json/%s" % a.id
	a.name = DefReader.string(d, "name", errs, w)
	a.weight = DefReader.number(d, "weight", errs, w, 1.0)
	a.hp_mult = DefReader.number(d, "hp_mult", errs, w, 1.0)
	a.tag = DefReader.id(d, "tag", errs, w)
	a.move = MonsterDef.move_from(DefReader.dict(d, "move", errs, w), errs, w)
	return a


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/affixes"
	b.per_week = DefReader.number(d, "per_week", errs, w)
	b.per_rank = DefReader.number(d, "per_rank", errs, w)
	b.max_affixes = DefReader.integer(d, "max", errs, w, 2)
	return b
