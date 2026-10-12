class_name SkillValidator
extends RefCounted
## Checks the skill webs (GDD 4.4): known node types, one start node, links to existing nodes, every node reachable
## from the start, blueprints, armor pieces, sample creatures and cards that exist; the Voice numbers.


static func validate(data: ContentData, errs: ErrorLog) -> void:
	for web: SkillDefs.WebDef in data.webs.values():
		var w := "skills/%s" % web.id
		var starts := 0
		for nd: SkillDefs.NodeDef in web.nodes.values():
			_node(data, web, nd, errs, w)
			starts += 1 if nd.type == &"start" else 0
		if starts != 1:
			errs.add(w, "needs exactly one start node")
		for id: StringName in web.order:
			if not _reachable(web, id):
				errs.add(w, "node '%s' cannot be reached from the start" % id)
	var b := data.balance.skills
	if b.node_cost < 1 or b.reset_cost_per_point < 0:
		errs.add("balance.json/skills", "node_cost >= 1, reset_cost_per_point >= 0")
	var v := data.balance.voice
	if v.stages.size() != 3 or data.card(v.rage_card) == null or data.card(v.beast_card) == null:
		errs.add("balance.json/voice", "needs 3 stages and existing rage_card and beast_card")
	if v.hunger_chance < 0.0 or v.hunger_chance > 1.0 or v.lose_control_chance < 0.0 or v.lose_control_chance > 1.0:
		errs.add("balance.json/voice", "chances must be in 0..1")
	if v.beast_money_share < 0.0 or v.beast_money_share > 1.0 or v.beast_hp_share < 0.0 or v.beast_hp_share > 1.0:
		errs.add("balance.json/voice", "beast_money_share and beast_hp_share must be in 0..1")
	for k: StringName in v.beast_outcomes:
		if not (k in VoiceRules.BEAST_OUTCOMES) or v.beast_outcomes[k] <= 0.0:
			errs.add("balance.json/voice", "unknown beast outcome '%s' or weight <= 0" % k)


static func _node(data: ContentData, web: SkillDefs.WebDef, nd: SkillDefs.NodeDef, errs: ErrorLog, w: String) -> void:
	var nw := "%s/%s" % [w, nd.id]
	if not SkillDefs.TYPES.has(nd.type):
		errs.add(nw, "unknown type '%s'" % nd.type)
	for l: StringName in nd.links:
		if web.node(l) == null:
			errs.add(nw, "link to unknown node '%s'" % l)
	if nd.type != &"start" and nd.links.is_empty():
		errs.add(nw, "needs a link")
	if nd.blueprint != &"" and data.blueprint(nd.blueprint) == null:
		errs.add(nw, "unknown blueprint '%s'" % nd.blueprint)
	if nd.sample != &"" and data.monster(nd.sample) == null:
		errs.add(nw, "unknown creature '%s' for the sample" % nd.sample)
	if nd.pure and nd.sample == &"":
		errs.add(nw, "a pure node needs a sample creature")
	if nd.voice < 0:
		errs.add(nw, "voice must be >= 0")
	for c: StringName in nd.cards:
		if data.card(c) == null:
			errs.add(nw, "unknown card '%s'" % c)
	if nd.socket != &"" and not data.armor.any(func(a: GearDefs.ArmorDef) -> bool: return a.id == nd.socket):
		errs.add(nw, "unknown armor piece '%s'" % nd.socket)
	_blood_cells(data, nd, nw, errs)


## Blood cells must be cells of the start weapon (the only weapon of the slice).
static func _blood_cells(data: ContentData, nd: SkillDefs.NodeDef, nw: String, errs: ErrorLog) -> void:
	var weapon := data.weapon(StringName(str(data.balance.start_loadout.get("start_weapon", ""))))
	for s: StringName in nd.blood_cells:
		var section: WeaponDef.SectionDef = weapon.section(s) if weapon != null else null
		for c: Variant in nd.blood_cells[s]:
			if section == null or section.cells.get(c as Vector2i, &"") != &"gear":
				errs.add(nw, "blood cell %s must be a gear cell of %s" % [c, s])


## Walks links back toward the start (links point to parents).
static func _reachable(web: SkillDefs.WebDef, id: StringName) -> bool:
	var seen := {}
	var todo: Array[StringName] = [id]
	while not todo.is_empty():
		var cur: StringName = todo.pop_back()
		var nd := web.node(cur)
		if nd == null or seen.has(cur):
			continue
		if nd.type == &"start":
			return true
		seen[cur] = true
		todo.append_array(nd.links)
	return false
