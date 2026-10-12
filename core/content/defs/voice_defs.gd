class_name VoiceDefs
extends RefCounted
## The "voice" block of balance.json (GDD 4.2, 4.4): stage thresholds, what each stage does, how the Voice falls,
## blood sample prices.


class Balance:
	var stages: Array[int] = []
	var per_will: int = 3
	var rage_card: StringName = &""
	var beast_card: StringName = &""
	var hunger_chance: float = 0.0
	var lose_control_chance: float = 0.0
	var rest_voice: int = 0
	var calm_voice: int = 0
	var calm_cost: int = 0
	var pure_sell_mult: int = 2


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/voice"
	b.stages = ProgressDefs.ints(DefReader.array(d, "stages", errs, w))
	b.per_will = DefReader.integer(d, "per_will", errs, w, 3)
	b.rage_card = DefReader.id(d, "rage_card", errs, w)
	b.beast_card = DefReader.id(d, "beast_card", errs, w)
	b.hunger_chance = DefReader.number(d, "hunger_chance", errs, w)
	b.lose_control_chance = DefReader.number(d, "lose_control_chance", errs, w)
	b.rest_voice = DefReader.integer(d, "rest_voice", errs, w)
	b.calm_voice = DefReader.integer(d, "calm_voice", errs, w)
	b.calm_cost = DefReader.integer(d, "calm_cost", errs, w)
	b.pure_sell_mult = DefReader.integer(d, "pure_sell_mult", errs, w, 2)
	return b
