class_name DistrictStateDef
extends RefCounted
## What a district state does (data/city/district_states.json, GDD 14.2).

var id: StringName
var art_suffix: String
var overlay: StringName = &""
var danger_delta: int = 0
var ring_growth_mult: float = 1.0
var shop_price_mult: float = 1.0
var next: StringName = &""
var permanent: bool = false
var monster_pool_add: Array[StringName] = []
var rumor_tag_weights: Dictionary[StringName, float] = {}
var infirmary_mult: float = 1.0  ## the Ash Sisters' prices
var shift_pay_mult: float = 1.0  ## a tavern shift's pay
var contract_reward_mult: float = 1.0  ## rewards of leaflets pinned while the state lasts
var rumor_bonus: int = 0  ## more rumors overheard a day (GDD 8.4)
var closed_actions: Array[StringName] = []  ## place actions shut while the state lasts


static func from_dict(state_id: StringName, d: Dictionary, errs: ErrorLog) -> DistrictStateDef:
	var x := DistrictStateDef.new()
	var w := "district_states.json/%s" % state_id
	x.id = state_id
	x.art_suffix = DefReader.string(d, "art_suffix", errs, w)
	x.overlay = DefReader.id(d, "overlay", errs, w, false)
	x.danger_delta = DefReader.integer(d, "danger_delta", errs, w)
	x.ring_growth_mult = DefReader.number(d, "ring_growth_mult", errs, w, 1.0)
	x.shop_price_mult = DefReader.number(d, "shop_price_mult", errs, w, 1.0)
	x.next = DefReader.id(d, "next", errs, w, false)
	x.permanent = DefReader.flag(d, "permanent")
	x.monster_pool_add = DefReader.ids(d, "monster_pool_add", errs, w)
	x.infirmary_mult = DefReader.number(d, "infirmary_mult", errs, w, 1.0, false)
	x.shift_pay_mult = DefReader.number(d, "shift_pay_mult", errs, w, 1.0, false)
	x.contract_reward_mult = DefReader.number(d, "contract_reward_mult", errs, w, 1.0, false)
	x.rumor_bonus = DefReader.integer(d, "rumor_bonus", errs, w, 0, false)
	x.closed_actions = DefReader.ids(d, "closed_actions", errs, w)
	var weights := DefReader.dict(d, "rumor_tag_weights", errs, w, false)
	for tag: Variant in weights:
		x.rumor_tag_weights[StringName(str(tag))] = float(weights[tag])
	return x
