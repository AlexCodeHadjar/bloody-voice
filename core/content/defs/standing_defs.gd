class_name StandingDefs
extends RefCounted
## The hunter's standing (GDD 10.3, 12): factions of the slice (data/factions/factions.json) and the "factions",
## "register" and "bestiary" blocks of balance.json.

const TIERS: Array[StringName] = [&"hostile", &"wary", &"neutral", &"trusted", &"sworn"]
const EFFECTS: Array[StringName] = [&"infirmary_mult", &"extra_signs", &"reward_mult"]
const KNOWLEDGE: Array[StringName] = [&"seen", &"fought", &"slain", &"captured", &"dissected"]


class FactionDef:
	var id: StringName
	var name: String
	var text: String
	var rivals: Array[StringName] = []
	var tiers: Dictionary[StringName, Dictionary] = {}  ## tier -> Dictionary[StringName, float] {effect: value}


class FactionBalance:
	var tier_min: Dictionary[StringName, int] = {}
	var petition_done: int = 0
	var rival_done: int = 0
	var outcome: Dictionary[StringName, Dictionary] = {}  ## fight outcome -> Dictionary[StringName, int] {faction: change}


class RegisterBalance:
	var ranks: Array[String] = []
	var exam_after: Array[int] = []
	var exam_days: int = 6
	var exam_reward: Array[int] = []
	var exam_xp: int = 0
	var reward_bonus: float = 0.0


class BestiaryBalance:
	var mods: Dictionary[StringName, Dictionary] = {}  ## knowledge mark -> GearMods


static func faction(d: Dictionary, errs: ErrorLog) -> FactionDef:
	var f := FactionDef.new()
	f.id = DefReader.id(d, "id", errs, "factions/factions.json")
	var w := "factions/factions.json/%s" % f.id
	f.name = DefReader.string(d, "name", errs, w)
	f.text = DefReader.string(d, "text", errs, w)
	f.rivals = DefReader.ids(d, "rivals", errs, w)
	var tiers := DefReader.dict(d, "tiers", errs, w)
	for k: Variant in tiers:  # keys become StringNames: effects are looked up by StringName
		var effects: Dictionary[StringName, float] = {}
		var src: Dictionary = tiers[k] if tiers[k] is Dictionary else {}
		for e: Variant in src:
			if not (src[e] is float or src[e] is int):
				errs.add(w, "effect '%s' needs a number" % e)
			effects[StringName(str(e))] = float(src[e]) if (src[e] is float or src[e] is int) else 0.0
		f.tiers[StringName(str(k))] = effects
	return f


static func factions_balance(d: Dictionary, errs: ErrorLog) -> FactionBalance:
	var b := FactionBalance.new()
	var w := "balance.json/factions"
	var mins := DefReader.dict(d, "tier_min", errs, w)
	for k: Variant in mins:
		b.tier_min[StringName(str(k))] = int(mins[k])
	b.petition_done = DefReader.integer(d, "petition_done", errs, w)
	b.rival_done = DefReader.integer(d, "rival_done", errs, w)
	var outcome := DefReader.dict(d, "outcome", errs, w)
	for k: Variant in outcome:
		b.outcome[StringName(str(k))] = WorkshopDefs.amounts(outcome[k] as Dictionary)
	return b


static func register_balance(d: Dictionary, errs: ErrorLog) -> RegisterBalance:
	var b := RegisterBalance.new()
	var w := "balance.json/register"
	for v: Variant in DefReader.array(d, "ranks", errs, w):
		b.ranks.append(str(v))
	b.exam_after = ProgressDefs.ints(DefReader.array(d, "exam_after", errs, w))
	b.exam_days = DefReader.integer(d, "exam_days", errs, w, 6)
	b.exam_reward = ProgressDefs.ints(DefReader.array(d, "exam_reward", errs, w))
	b.exam_xp = DefReader.integer(d, "exam_xp", errs, w)
	b.reward_bonus = DefReader.number(d, "reward_bonus", errs, w)
	return b


static func bestiary_balance(d: Dictionary, errs: ErrorLog) -> BestiaryBalance:
	var b := BestiaryBalance.new()
	var mods := DefReader.dict(d, "mods", errs, "balance.json/bestiary")
	for k: Variant in mods:  # each mark's bonuses are GearMods (unknown names are data errors)
		b.mods[StringName(str(k))] = GearMods.read({"mods": mods[k]}, errs, "balance.json/bestiary/mods/%s" % k)
	return b
