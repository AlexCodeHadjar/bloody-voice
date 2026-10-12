class_name HealthDefs
extends RefCounted
## The "health" block of balance.json (GDD 4, owner 2026-10-12): rest, infirmary prices, the Hunter's Fall fee.


class Balance:
	var rest_share: float = 0.33
	var treat_base: int = 0
	var treat_per_hp: int = 0
	var treat_per_sanity: int = 0
	var fall_fee: int = 0


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/health"
	b.rest_share = DefReader.number(d, "rest_share", errs, w, 0.33)
	b.treat_base = DefReader.integer(d, "treat_base", errs, w)
	b.treat_per_hp = DefReader.integer(d, "treat_per_hp", errs, w)
	b.treat_per_sanity = DefReader.integer(d, "treat_per_sanity", errs, w)
	b.fall_fee = DefReader.integer(d, "fall_fee", errs, w)
	return b
