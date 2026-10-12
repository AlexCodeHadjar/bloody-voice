class_name LibraryRules
extends RefCounted
## The Crypt Scriptorium (GDD 3.3, owner 2026-10-12): a day there verifies one rumor (shows what it leads to) or
## studies one trophy (it is spent; every open contract and leaflet on that creature learns one more sign, and the
## Bestiary marks the creature dissected, GDD 10.3). The caller ends the day.


class Study:
	var creature: StringName
	var taught: Array[ContractsState.Contract] = []  ## contracts that learned a sign
	var dissected: bool = false  ## the Bestiary mark is new


static func can_verify(run: RunState, uid: int) -> String:
	var r := run.rumors.find(uid)
	if r == null or r.investigated:
		return Loc.t("rule.library.no_rumor")
	if r.verified:
		return Loc.t("rule.library.verified")
	if r.expires_day <= run.day + 1:  # the day spent here would let it cool before it could be used
		return Loc.t("rule.library.cools")
	return ""


static func verify(run: RunState, uid: int) -> String:
	var problem := can_verify(run, uid)
	if problem == "":
		run.rumors.find(uid).verified = true
	return problem


## The creature a trophy comes from (the first that drops it); &"" if none.
static func trophy_creature(data: ContentData, trophy: StringName) -> StringName:
	for id: StringName in data.monster_order:
		for p: MonsterDef.PartDef in data.monster(id).parts:
			if p.trophy == trophy:
				return id
	return &""


## Contracts (taken or on the board, not done) on the creature that could still learn a sign.
static func contracts_to_teach(run: RunState, data: ContentData, monster: StringName) -> Array[ContractsState.Contract]:
	var out: Array[ContractsState.Contract] = []
	var m := data.monster(monster)
	for c: ContractsState.Contract in run.contracts.items:
		if c.monster == monster and not c.done and c.known_tags.size() < m.tags.size():
			out.append(c)
	return out


static func can_study(run: RunState, data: ContentData, trophy: StringName) -> String:
	if run.workshop.amount(trophy) <= 0:
		return Loc.t("rule.library.no_trophy")
	var creature := trophy_creature(data, trophy)
	if creature == &"":
		return Loc.t("rule.library.nothing_to_learn")
	if contracts_to_teach(run, data, creature).is_empty() and run.bestiary.has(creature, &"dissected"):
		return Loc.t("rule.library.nothing_to_learn")
	return ""


## Spends the trophy; each contract on its creature learns the first sign it did not know; the creature is marked
## dissected. null when it can't be done.
static func study(run: RunState, data: ContentData, trophy: StringName) -> Study:
	if can_study(run, data, trophy) != "":
		return null
	var out := Study.new()
	var monster := trophy_creature(data, trophy)
	out.creature = monster
	out.dissected = BestiaryRules.mark(run, monster, &"dissected")
	run.workshop.trophies[trophy] -= 1
	if run.workshop.trophies[trophy] <= 0:
		run.workshop.trophies.erase(trophy)
	for c: ContractsState.Contract in contracts_to_teach(run, data, monster):
		for t: StringName in data.monster(monster).tags:
			if not c.known_tags.has(t):
				c.known_tags.append(t)
				break
		out.taught.append(c)
	return out
