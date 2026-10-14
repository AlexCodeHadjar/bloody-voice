class_name ProgressDefs
extends RefCounted
## The "progress" block of balance.json (GDD 4.1–4.3): XP, levels, points, what each attribute does.

const ATTRIBUTES: Array[StringName] = [&"will", &"agility", &"cunning"]


class Balance:
	var level_cap: int = 15
	var xp_base: int = 50
	var xp_per_level: int = 25
	var xp_by_rank: Dictionary[String, int] = {}
	var capture_xp_mult: float = 1.5
	var contract_xp: int = 0
	var skill_points_per_level: int = 1
	var bonus_point_levels: Array[int] = []
	var attribute_point_every: int = 2
	var start_attributes: Dictionary[StringName, int] = {}
	var sanity_per_will: int = 4
	var agility_hand_at: Array[int] = []
	var dodge_per_agility: float = 0.0
	var cunning_preview_at: Array[int] = []
	var flag_per_cunning: float = 0.0
	var discount_per_cunning: float = 0.0
	var max_discount: float = 0.0


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/progress"
	for key: String in ["level_cap", "xp_base", "xp_per_level", "contract_xp", "skill_points_per_level",
			"attribute_point_every", "sanity_per_will"]:
		b.set(key, DefReader.integer(d, key, errs, w))
	for key: String in ["capture_xp_mult", "dodge_per_agility", "flag_per_cunning", "discount_per_cunning", "max_discount"]:
		b.set(key, DefReader.number(d, key, errs, w))
	var ranks := DefReader.dict(d, "xp_by_rank", errs, w)
	for r: Variant in ranks:
		b.xp_by_rank[str(r)] = int(ranks[r])
	b.bonus_point_levels = ints(DefReader.array(d, "bonus_point_levels", errs, w))
	b.agility_hand_at = ints(DefReader.array(d, "agility_hand_at", errs, w))
	b.cunning_preview_at = ints(DefReader.array(d, "cunning_preview_at", errs, w))
	b.start_attributes = WorkshopDefs.amounts(DefReader.dict(d, "start_attributes", errs, w))
	return b


static func ints(a: Array) -> Array[int]:
	var out: Array[int] = []
	for v: Variant in a:
		out.append(int(v))
	return out
