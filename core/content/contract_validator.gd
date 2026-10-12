class_name ContractValidator
extends RefCounted
## Checks contract content (GDD 7, 8.2): every creature tag is in the catalogue, petitions cover the generated
## types, the balance numbers make sense and the start district has creatures to hunt.


static func validate(data: ContentData, errs: ErrorLog) -> void:
	_tags(data, errs)
	_petitions(data, errs)
	_balance(data, errs)


static func _tags(data: ContentData, errs: ErrorLog) -> void:
	for t: ContractDefs.TagDef in data.tags.values():
		if not ContractDefs.CATEGORIES.has(t.category):
			errs.add("contracts/tags.json/%s" % t.id, "unknown category '%s'" % t.category)
	for m: MonsterDef in data.monsters.values():
		if m.tags.size() < data.balance.contracts.known_tags_max:
			errs.add("monsters/%s" % m.id, "needs at least %d tags (known_tags_max)" % data.balance.contracts.known_tags_max)
		for tag_id: StringName in m.tags:
			if not data.tags.has(tag_id):
				errs.add("monsters/%s" % m.id, "tag '%s' is not in contracts/tags.json" % tag_id)


static func _petitions(data: ContentData, errs: ErrorLog) -> void:
	var covered := {}
	for p: ContractDefs.PetitionDef in data.petitions:
		if p.types.is_empty():
			errs.add("contracts/petitions.json/%s" % p.id, "needs at least one type")
		for t: StringName in p.types:
			if not ContractDefs.TYPES.has(t):
				errs.add("contracts/petitions.json/%s" % p.id, "unknown type '%s'" % t)
			covered[t] = true
	for t: StringName in data.balance.contracts.type_weights:
		if not covered.has(t):
			errs.add("contracts/petitions.json", "no petition for type '%s'" % t)


static func _balance(data: ContentData, errs: ErrorLog) -> void:
	var c := data.balance.contracts
	var w := "balance.json/contracts"
	if c.board_min < 1 or c.board_max < c.board_min:
		errs.add(w, "need 1 <= board_min <= board_max")
	if c.deadline_min < 1 or c.deadline_max < c.deadline_min:
		errs.add(w, "need 1 <= deadline_min <= deadline_max")
	if c.known_tags_min < 1 or c.known_tags_max < c.known_tags_min:
		errs.add(w, "need 1 <= known_tags_min <= known_tags_max")
	if c.max_active < 1 or c.max_same_type < 1 or c.max_same_monster < 1:
		errs.add(w, "max_active, max_same_type and max_same_monster must be >= 1")
	if c.overdue_hp_mult < 1.0 or c.overdue_damage_bonus < 0:
		errs.add(w, "overdue_hp_mult must be >= 1 and overdue_damage_bonus >= 0")
	if c.type_weights.is_empty():
		errs.add(w, "type_weights is empty")
	for t: StringName in c.type_weights:
		if not ContractDefs.GENERATED.has(t) or c.type_weights[t] <= 0.0:
			errs.add(w, "type_weights: '%s' must be one of %s with a weight > 0" % [t, ContractDefs.GENERATED])
	for m: MonsterDef in data.monsters.values():
		if not c.reward_by_rank.has(m.rank):
			errs.add(w, "reward_by_rank has no rank '%s' (monster %s)" % [m.rank, m.id])
	if EncounterRules.pool(data, data.balance.start_district).is_empty():
		errs.add(w, "no creature lives in the start district %s" % data.balance.start_district)
