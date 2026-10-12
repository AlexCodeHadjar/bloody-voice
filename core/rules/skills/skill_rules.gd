class_name SkillRules
extends RefCounted
## The skill webs (GDD 4.4, owner 2026-10-12): a node is bought for skill points of the shared pool when a node it
## links to is owned; its effect — passive bonuses, a learned blueprint (its trophy is still needed to craft),
## armor sockets, workshop crafts, fight cards — counts while owned. A Monster-web node also uses up a blood sample
## of its creature (a keystone a pure one) and raises the Voice (GDD 4.4). Resetting the Mechanic web refunds its
## points for money in the Scriptorium; learned blueprints stay. The Monster web is never reset.


static func is_owned(run: RunState, web: SkillDefs.WebDef, node_id: StringName) -> bool:
	var nd := web.node(node_id)
	return nd != null and (nd.type == &"start" or run.skills.owned_in(web.id).has(node_id))


## "" or why the node can't be bought now.
static func can_buy(run: RunState, data: ContentData, web: SkillDefs.WebDef, node_id: StringName) -> String:
	var nd := web.node(node_id)
	if nd == null:
		return Loc.t("rule.skill.unknown")
	if is_owned(run, web, node_id):
		return Loc.t("rule.skill.owned")
	if not nd.links.any(func(l: StringName) -> bool: return is_owned(run, web, l)):
		return Loc.t("rule.skill.not_linked")
	if run.progress.skill_points < data.balance.skills.node_cost:
		return Loc.t("rule.skill.no_points")
	return _sample_problem(run, data, nd)


## "" or why the node's blood sample is missing: a keystone needs a pure one, a formula takes either.
static func _sample_problem(run: RunState, data: ContentData, nd: SkillDefs.NodeDef) -> String:
	if nd.sample == &"":
		return ""
	var ws := run.workshop
	var creature: String = data.monster(nd.sample).name if data.monster(nd.sample) != null else String(nd.sample)
	if nd.pure:
		return "" if ws.pure_samples.get(nd.sample, 0) > 0 else Loc.t("rule.skill.no_pure", {"name": creature})
	if ws.samples.get(nd.sample, 0) + ws.pure_samples.get(nd.sample, 0) <= 0:
		return Loc.t("rule.skill.no_sample", {"name": creature})
	return ""


## Uses up the node's sample: a normal one first, a pure one only when needed.
static func _use_sample(ws: WorkshopState, nd: SkillDefs.NodeDef) -> void:
	if nd.sample == &"":
		return
	var pool: Dictionary[StringName, int] = ws.samples if not nd.pure and ws.samples.get(nd.sample, 0) > 0 else ws.pure_samples
	pool[nd.sample] = pool.get(nd.sample, 0) - 1
	if pool[nd.sample] <= 0:
		pool.erase(nd.sample)


static func buy(run: RunState, data: ContentData, web: SkillDefs.WebDef, node_id: StringName) -> String:
	var problem := can_buy(run, data, web, node_id)
	if problem != "":
		return problem
	var list := run.skills.owned_in(web.id)
	list.append(node_id)
	run.skills.owned[web.id] = list
	run.progress.skill_points -= data.balance.skills.node_cost
	var nd := web.node(node_id)
	if nd.blueprint != &"" and not run.workshop.blueprints.has(nd.blueprint):
		run.workshop.blueprints.append(nd.blueprint)
	_use_sample(run.workshop, nd)
	run.voice += nd.voice
	sync_sockets(run, data)
	return ""


## Owned nodes of every web (start nodes excluded).
static func owned_nodes(run: RunState, data: ContentData) -> Array[SkillDefs.NodeDef]:
	var out: Array[SkillDefs.NodeDef] = []
	for web: SkillDefs.WebDef in data.webs.values():
		for id: StringName in run.skills.owned_in(web.id):
			var nd := web.node(id)
			if nd != null:
				out.append(nd)
	return out


## Passive bonuses of every owned node (GearMods), added to the fight's mods.
static func mods(run: RunState, data: ContentData) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	for nd: SkillDefs.NodeDef in owned_nodes(run, data):
		GearMods.sum(out, nd.mods)
	return out


## Cards the owned nodes add to every fight's deck.
static func cards(run: RunState, data: ContentData) -> Array[StringName]:
	var out: Array[StringName] = []
	for nd: SkillDefs.NodeDef in owned_nodes(run, data):
		out.append_array(nd.cards)
	return out


## Extra crafts in a workshop day.
static func crafts_bonus(run: RunState, data: ContentData) -> int:
	var n := 0
	for nd: SkillDefs.NodeDef in owned_nodes(run, data):
		n += nd.crafts
	return n


## Rewrites the loadout's extra sockets from the owned nodes; mechanisms in sockets that vanished go back to spare.
static func sync_sockets(run: RunState, data: ContentData) -> void:
	var extra: Dictionary[StringName, int] = {}
	for nd: SkillDefs.NodeDef in owned_nodes(run, data):
		if nd.socket != &"":
			extra[nd.socket] = extra.get(nd.socket, 0) + 1
		if nd.sockets_all > 0:
			for a: GearDefs.ArmorDef in data.armor:
				extra[a.id] = extra.get(a.id, 0) + nd.sockets_all
	run.loadout.extra_sockets = extra
	ArmorRules.trim(run.loadout, data)


static func reset_cost(run: RunState, data: ContentData, web: SkillDefs.WebDef) -> int:
	return run.skills.owned_in(web.id).size() * data.balance.skills.reset_cost_per_point


static func can_reset(run: RunState, data: ContentData, web: SkillDefs.WebDef) -> String:
	if web.id == &"monster":  # what the blood has taught can't be unlearned
		return Loc.t("rule.skill.no_reset")
	if run.skills.owned_in(web.id).is_empty():
		return Loc.t("rule.skill.nothing_to_reset")
	if run.money < reset_cost(run, data, web):
		return Loc.t("rule.skill.no_money")
	return ""


## Refunds the web's points for money; learned blueprints stay.
static func reset(run: RunState, data: ContentData, web: SkillDefs.WebDef) -> String:
	var problem := can_reset(run, data, web)
	if problem != "":
		return problem
	run.money -= reset_cost(run, data, web)
	run.progress.skill_points += run.skills.owned_in(web.id).size() * data.balance.skills.node_cost
	run.skills.owned.erase(web.id)
	sync_sockets(run, data)
	return ""
