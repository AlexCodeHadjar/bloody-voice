class_name StandingValidator
extends RefCounted
## Checks the hunter's standing content (GDD 10.3, 12): factions (rivals, tiers, effects), petition factions, the
## reputation tiers and changes, the Register ranks and exam numbers, the Bestiary marks.


static func validate(data: ContentData, errs: ErrorLog) -> void:
	_factions(data, errs)
	_reputation(data, errs)
	_register(data, errs)
	for k: StringName in data.balance.bestiary.mods:
		if not StandingDefs.KNOWLEDGE.has(k):
			errs.add("balance.json/bestiary", "unknown knowledge mark '%s'" % k)


static func _factions(data: ContentData, errs: ErrorLog) -> void:
	for f: StandingDefs.FactionDef in data.factions:
		var w := "factions/factions.json/%s" % f.id
		for r: StringName in f.rivals:
			if data.faction(r) == null or r == f.id:
				errs.add(w, "unknown rival '%s'" % r)
		for t: StringName in f.tiers:
			if not StandingDefs.TIERS.has(t):
				errs.add(w, "unknown tier '%s'" % t)
			for e: Variant in f.tiers[t]:
				if not StandingDefs.EFFECTS.has(StringName(str(e))):
					errs.add(w, "unknown effect '%s' in tier '%s'" % [e, t])
	for p: ContractDefs.PetitionDef in data.petitions:
		if p.faction != &"" and data.faction(p.faction) == null:
			errs.add("contracts/petitions.json/%s" % p.id, "unknown faction '%s'" % p.faction)
	if data.petition(&"register_exam") == null:
		errs.add("contracts/petitions.json", "needs the 'register_exam' petition")


static func _reputation(data: ContentData, errs: ErrorLog) -> void:
	var b := data.balance.factions
	var last := -1000
	for t: StringName in StandingDefs.TIERS:
		if not b.tier_min.has(t) or b.tier_min[t] <= last:
			errs.add("balance.json/factions", "tier_min needs every tier, rising: %s" % t)
		last = int(b.tier_min.get(t, last))
	for o: StringName in b.outcome:
		if not (o in [&"slain", &"captured"]):
			errs.add("balance.json/factions", "unknown outcome '%s'" % o)
		for f: Variant in b.outcome[o]:
			if data.faction(StringName(str(f))) == null:
				errs.add("balance.json/factions", "unknown faction '%s'" % f)


static func _register(data: ContentData, errs: ErrorLog) -> void:
	var r := data.balance.register
	var steps := r.ranks.size() - 1
	if steps < 1 or r.exam_after.size() != steps or r.exam_reward.size() != steps:
		errs.add("balance.json/register", "exam_after and exam_reward need one value per rank step")
	if r.exam_days < 1:
		errs.add("balance.json/register", "exam_days must be >= 1")
	for id: StringName in data.monster_order:
		var m := data.monster(id)
		if m != null and not r.ranks.has(m.rank):  # the loader fills monster_order; only a broken test order has unknown ids
			errs.add("monsters/%s" % id, "rank '%s' is not in balance.json/register" % m.rank)
