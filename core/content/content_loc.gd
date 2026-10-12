class_name ContentLoc
extends RefCounted
## Puts the game-language texts into loaded content (GDD 22.5). Data JSON keeps ids, numbers and the English working
## names; the shown text comes from locale/strings.csv by key, e.g. card.strike.name, monster.vigil_hound.part.jaw.
## Screens keep reading def.name / def.text, so they need no changes. A key missing from the table keeps the English
## text (tests list every missing key).


static func apply(data: ContentData) -> void:
	for f: Dictionary in fields(data):
		var owner: Object = f["owner"]
		var prop: StringName = f["prop"]
		owner.set(prop, Loc.or_default(f["key"] as String, str(owner.get(prop))))
	for district: DistrictDef in data.districts.values():
		for area: StringName in district.area_names.keys():
			var key := "district.%s.area.%s" % [district.id, area]
			district.area_names[area] = Loc.or_default(key, district.area_names[area])


## Every translatable content text: [{owner, prop, key}] (area names are a dictionary, see area_keys()).
static func fields(data: ContentData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: CardDef in data.cards.values():
		_add(out, c, "card.%s" % c.id, ["name", "text"])
	for m: MonsterDef in data.monsters.values():
		_monster(out, m)
	for w: WeaponDef in data.weapons.values():
		_add(out, w, "weapon.%s" % w.id, ["name"])
		for s: WeaponDef.SectionDef in w.sections:
			_add(out, s, "weapon.%s.section.%s" % [w.id, s.id], [""])
	for mo: ModuleDef in data.modules.values():
		_add(out, mo, "module.%s" % mo.id, ["name", "effect"])
		for i: int in mo.tiers.size():
			_add(out, mo.tiers[i], "module.%s.tier.%d" % [mo.id, i + 2], ["effect"])
	for me: GearDefs.MechanismDef in data.mechanisms.values():
		_add(out, me, "mechanism.%s" % me.id, ["name", "effect"])
	for a: GearDefs.ArmorDef in data.armor:
		_add(out, a, "armor.%s" % a.id, ["name"])
	for sh: GearDefs.ShapeDef in data.shapes.values():
		_add(out, sh, "shape.%s" % sh.id, ["name"])
	for d: DistrictDef in data.districts.values():
		_add(out, d, "district.%s" % d.id, ["name", "district_class", "controller", "danger", "look"])
	for dm: DistrictMapDef in data.district_maps.values():
		_district_map(out, dm)
	for t: ContractDefs.TagDef in data.tags.values():
		_add(out, t, "tag.%s" % t.id, [""])
	for pe: ContractDefs.PetitionDef in data.petitions:
		_add(out, pe, "petition.%s" % pe.id, ["sender", "text"])
	for wi: RumorDefs.Witness in data.rumor_data.witnesses:
		_add(out, wi, "rumor_witness.%s" % wi.id, ["text"])
	for web: SkillDefs.WebDef in data.webs.values():
		for nd: SkillDefs.NodeDef in web.nodes.values():
			_add(out, nd, "skill.%s.%s" % [web.id, nd.id], ["name", "text"])
	for g: RumorDefs.Witness in data.rumor_data.gossip:
		_add(out, g, "rumor_gossip.%s" % g.id, ["text"])
	return out


## Area name keys -> English text (for the tests).
static func area_keys(data: ContentData) -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	for d: DistrictDef in data.districts.values():
		for area: StringName in d.area_names.keys():
			out["district.%s.area.%s" % [d.id, area]] = d.area_names[area]
	return out


static func _district_map(out: Array[Dictionary], dm: DistrictMapDef) -> void:
	var base := "district_map.%s" % dm.district
	for l: DistrictMapDef.LandmarkDef in dm.landmarks:
		_add(out, l, "%s.landmark.%s" % [base, l.id], ["name", "desc"])
	for st: DistrictMapDef.StreetDef in dm.streets:
		_add(out, st, "%s.street.%s" % [base, st.id], [""])
	for z: DistrictMapDef.ZoneDef in dm.zones:
		_add(out, z, "%s.zone.%s" % [base, z.id], [""])


static func _monster(out: Array[Dictionary], m: MonsterDef) -> void:
	var base := "monster.%s" % m.id
	_add(out, m, base, ["name"])
	for p: MonsterDef.PartDef in m.parts:
		_add(out, p, "%s.part.%s" % [base, p.id], [""])
	for mv: MonsterDef.MoveDef in m.moves.values():
		_add(out, mv, "%s.move.%s" % [base, mv.id], [""])
	for i: int in m.phases.size():
		_add(out, m.phases[i], "%s.phase.%d" % [base, i], [""])


## props: field names; "" means the key itself names the object's `name` (monster.x.part.jaw -> part.name).
static func _add(out: Array[Dictionary], owner: Object, base: String, props: Array) -> void:
	for p: String in props:
		var prop := "name" if p == "" else p
		var key := base if p == "" else "%s.%s" % [base, _key_field(p)]
		out.append({"owner": owner, "prop": StringName(prop), "key": key})


static func _key_field(prop: String) -> String:
	match prop:
		"district_class":
			return "class"
		"sender":
			return "from"
	return prop
