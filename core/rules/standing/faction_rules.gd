class_name FactionRules
extends RefCounted
## Reputation (GDD 12, owner 2026-10-12: the slice has the Grey Communion and the Iron Vigil). −100..100, tiers by
## balance.json/factions.tier_min. A finished contract raises its petitioner's faction and lowers its rivals; every
## won fight moves them by outcome. A tier's effects (factions.json) change infirmary prices, leaflet signs, rewards.

const MIN_REP := -100
const MAX_REP := 100


static func tier(run: RunState, data: ContentData, faction: StringName) -> StringName:
	var value := run.standing.rep(faction)
	var out: StringName = StandingDefs.TIERS[0]
	for t: StringName in StandingDefs.TIERS:
		if value >= data.balance.factions.tier_min.get(t, MAX_REP + 1):
			out = t
	return out


## The product of a multiplying effect over every faction's current tier (1.0 = none).
static func mult(run: RunState, data: ContentData, effect: StringName) -> float:
	var v := 1.0
	for f: StandingDefs.FactionDef in data.factions:
		v *= float((f.tiers.get(tier(run, data, f.id), {}) as Dictionary).get(effect, 1.0))
	return v


## The sum of an adding effect over every faction's current tier.
static func bonus(run: RunState, data: ContentData, effect: StringName) -> int:
	var n := 0
	for f: StandingDefs.FactionDef in data.factions:
		n += int((f.tiers.get(tier(run, data, f.id), {}) as Dictionary).get(effect, 0))
	return n


## Changes a fight brings (pure; the result panel shows them): the outcome's, plus the petition's when the fight
## finishes contract `c`.
static func fight_changes(data: ContentData, c: ContractsState.Contract, outcome: StringName) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	var b := data.balance.factions
	var by_outcome: Dictionary = b.outcome.get(outcome, {})
	for f: Variant in by_outcome:
		_add(out, StringName(str(f)), int(by_outcome[f]))
	if ContractRules.reward_for(c, outcome) <= 0:
		return out
	var p := data.petition(c.petition)
	var fd := data.faction(p.faction) if p != null else null
	if fd != null:
		_add(out, fd.id, b.petition_done)
		for r: StringName in fd.rivals:
			_add(out, r, b.rival_done)
	return out


static func apply(run: RunState, changes: Dictionary[StringName, int]) -> void:
	for f: StringName in changes:
		run.standing.reputation[f] = clampi(run.standing.rep(f) + changes[f], MIN_REP, MAX_REP)


static func _add(into: Dictionary[StringName, int], f: StringName, n: int) -> void:
	into[f] = into.get(f, 0) + n
	if into[f] == 0:
		into.erase(f)
