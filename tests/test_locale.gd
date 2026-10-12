extends TestSuite
## The game speaks Russian (GDD 22.5): every key used by code and data has a Russian text, placeholders agree with
## the English column, and Russian plural forms are right.

const CODE_DIRS: Array[String] = ["res://core", "res://scenes", "res://ui", "res://autoload"]


func test_russian_plural_forms() -> void:
	var expect := {0: "карт", 1: "карту", 2: "карты", 4: "карты", 5: "карт", 11: "карт", 12: "карт", 14: "карт",
		20: "карт", 21: "карту", 22: "карты", 24: "карты", 25: "карт", 30: "карт", 101: "карту", 111: "карт"}
	for n: int in expect:
		eq(Loc.format("{n:карту|карты|карт}", {"n": n}), expect[n], "plural for %d" % n)
	eq(Loc.t("effect.draw", {"n": 21}), "взять 21 карту", "effect template with plural")


func test_every_content_text_has_russian() -> void:
	var data := load_content(false)
	var missing: PackedStringArray = []
	for f: Dictionary in ContentLoc.fields(data):
		if not Loc.has(f["key"] as String):
			missing.append(f["key"] as String)
	for key: String in ContentLoc.area_keys(data):
		if not Loc.has(key):
			missing.append(key)
	check(missing.is_empty(), "content without Russian text (run python tools/gen_locale.py): %s" % ", ".join(missing))
	eq(data.card(&"strike").name, "Удар", "content names are shown in Russian")


func test_key_families_exist() -> void:
	var data := load_content(false)
	var keys: PackedStringArray = []
	for t: StringName in CardDef.TYPES:
		keys.append("card_type.%s" % t)
	for c: String in ["gear", "spark", "blood"]:
		keys.append("cell.%s" % c)
	for m: StringName in GearMods.ALL:
		keys.append("mod.%s" % m)
	for s: StringName in EffectSchema.STATUSES:
		keys.append("status.%s.name" % s)
	for op: StringName in EffectSchema.OPS:
		if not [&"damage", &"apply_status", &"add_card"].has(op):
			keys.append("effect.%s" % op)
	for s: StringName in data.district_states:
		keys.append("state.%s.name" % s)
	for i: int in data.balance.days_per_week:
		keys.append("ui.weekday.%d" % i)
	for o: String in ["slain", "captured", "fallen", "escaped"]:
		keys.append("ui.combat.outcome.%s" % o)
	for t: StringName in ContractDefs.TYPES:
		keys.append("ui.contract.type.%s" % t)
	for k: StringName in ShopDefs.KINDS:
		keys.append("ui.shop.kind.%s" % k)
	for r: StringName in data.balance.workshop.resources:
		keys.append("resource.%s" % r)
	for k: StringName in RumorDefs.KINDS:
		keys.append("ui.rumor.outcome.%s" % k)
		if not RumorDefs.FIGHTS.has(k):
			keys.append("ui.rumor.outcome.%s.text" % k)
	for m: MonsterDef in data.monsters.values():
		for mv: MonsterDef.MoveDef in m.moves.values():
			keys.append("intent.%s" % mv.kind)
		for p: MonsterDef.PartDef in m.parts:
			if p.trophy != &"":
				keys.append("trophy.%s" % p.trophy)
	for mo: ModuleDef in data.modules.values():
		keys.append("section.%s" % mo.section)
	_check_keys(keys, "key families")


func test_keys_written_in_code_exist() -> void:
	var re := RegEx.create_from_string("Loc\\.(?:t|or_default|has)\\(\"([a-z_.0-9]+)\"")
	var keys: PackedStringArray = []
	for dir: String in CODE_DIRS:
		for path: String in _scripts(dir):
			for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
				if not keys.has(m.get_string(1)):
					keys.append(m.get_string(1))
	check(keys.size() > 50, "found the keys used in code (%d)" % keys.size())
	_check_keys(keys, "keys in code")


func test_placeholders_agree_with_english() -> void:
	var ru := TranslationServer.get_translation_object("ru")
	var en := TranslationServer.get_translation_object("en")
	check(ru != null and en != null, "both translations are loaded")
	if ru == null or en == null:
		return
	var bad: PackedStringArray = []
	for key: StringName in ru.get_message_list():
		var ru_text := String(ru.get_message(key))
		var en_text := String(en.get_message(key))
		if ru_text == "":
			bad.append("%s: empty" % key)
		for p: String in Loc.placeholders(ru_text):
			if not Loc.placeholders(en_text).has(p):
				bad.append("%s: {%s} not in English" % [key, p])
	check(bad.is_empty(), "placeholder problems: %s" % "; ".join(bad))


func _check_keys(keys: PackedStringArray, what: String) -> void:
	var missing: PackedStringArray = []
	for k: String in keys:
		if not Loc.has(k):
			missing.append(k)
	check(missing.is_empty(), "%s without Russian text: %s" % [what, ", ".join(missing)])


func _scripts(dir: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		out.append_array(_scripts(dir.path_join(sub)))
	return out
