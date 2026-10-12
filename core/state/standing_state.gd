class_name StandingState
extends RefCounted
## The hunter's standing (GDD 12): reputation with the factions and the Register rank. Saved. FactionRules and
## RegisterRules change it; screens only read it.

var reputation: Dictionary[StringName, int] = {}  ## faction -> -100..100 (missing = 0)
var rank: int = 0  ## index into balance.json/register.ranks (0 = A)
var rank_contracts: int = 0  ## contracts finished since the last rank (the exam opens at exam_after)
var exam_block_week: int = 0  ## a failed exam: no new exam leaflet this week


func rep(faction: StringName) -> int:
	return reputation.get(faction, 0)


func to_dict() -> Dictionary:
	return {"reputation": reputation.duplicate(), "rank": rank, "rank_contracts": rank_contracts,
		"exam_block_week": exam_block_week}


static func from_dict(d: Dictionary) -> StandingState:
	var s := StandingState.new()
	s.reputation = WorkshopDefs.amounts(d.get("reputation", {}) as Dictionary)
	s.rank = int(d.get("rank", 0))
	s.rank_contracts = int(d.get("rank_contracts", 0))
	s.exam_block_week = int(d.get("exam_block_week", 0))
	return s
