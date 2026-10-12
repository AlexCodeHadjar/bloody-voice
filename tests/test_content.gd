extends TestSuite
## Real content is valid; the validator catches typical mistakes.


func test_real_content_is_valid() -> void:
	var data := load_content()
	eq(data.districts.size(), 12, "district count")
	check(data.district_states.has(&"normal"), "has normal state")
	check(data.map_regions.regions.size() >= 12, "map regions")


## Every icon in the catalog data/ui/icons.json has its imported art (screens show icons by id).
func test_every_icon_has_art() -> void:
	var sets: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/icons.json"))
	var missing: PackedStringArray = []
	for s: Dictionary in sets:
		for icon: Dictionary in s["icons"]:
			var path := Icons.path(s["set"] as String, StringName(icon["id"] as String))
			if not ResourceLoader.exists(path):
				missing.append(path.get_file())
	check(missing.is_empty(), "icons without art: %s" % ", ".join(missing))


func test_missing_creature_art_is_reported() -> void:
	var data := load_content()
	var m: MonsterDef = data.monsters.values()[0]
	m.id = &"no_such_creature"
	var errs := ErrorLog.new()
	ContentValidator.validate(data, errs, true)
	check(_has(errs.messages, "missing art"), "missing creature art must fail")


func test_bad_weekday_is_reported() -> void:
	var data := load_content(false)
	data.balance.rent_weekday = 9
	check(_errors(data).size() > 0, "rent_weekday 9 must fail")


func test_unknown_region_district_is_reported() -> void:
	var data := load_content(false)
	data.map_regions.regions[0].district = &"NOWHERE"
	check(_has(_errors(data), "unknown district"), "unknown district must fail")


func test_duplicate_symbol_is_reported() -> void:
	var data := load_content(false)
	data.districts[&"CROWN"].symbol = data.districts[&"SILVERHILL"].symbol
	check(_has(_errors(data), "already used"), "duplicate symbol must fail")


func test_missing_normal_state_is_reported() -> void:
	var data := load_content(false)
	data.district_states.erase(&"normal")
	check(_has(_errors(data), "'normal' is required"), "missing normal must fail")


func test_broken_json_is_reported() -> void:
	var errs := ErrorLog.new()
	var path := "user://broken_test.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{ \"a\": ")
	f.close()
	ContentLoader.read_object(path, errs)
	check(_has(errs.messages, "JSON error"), "broken JSON must be reported")


func test_move_text_field_is_rejected() -> void:
	var errs := ErrorLog.new()
	MonsterDef.from_dict({"id": "x", "name": "X", "rank": "A", "hp": 5, "deck": ["hit"],
		"moves": [{"id": "hit", "name": "Hit", "kind": "attack", "text": "old", "effects": [{"op": "damage", "amount": 1}]}]},
		errs, "test.json")
	check(_has(errs.messages, "remove 'text'"), "leftover move text must be reported")


func _errors(data: ContentData) -> PackedStringArray:
	var errs := ErrorLog.new()
	ContentValidator.validate(data, errs, false)
	return errs.messages


func _has(messages: PackedStringArray, needle: String) -> bool:
	for m: String in messages:
		if m.contains(needle):
			return true
	return false


## Sounds (GDD 24): every file in data/audio/sounds.json exists and every creature has its own voice.
func test_missing_sound_is_reported() -> void:
	var data := load_content()
	check(data.audio.sounds.has(&"ui.click"), "sounds are loaded")
	var click: AudioDef.SoundDef = data.audio.sounds[&"ui.click"]
	click.files = ["res://audio/sfx/NO_SUCH__sound.ogg"]
	var m: MonsterDef = data.monsters.values()[0]
	data.monster_order[0] = &"no_such_creature"
	var errs := ErrorLog.new()
	ContentValidator.validate(data, errs, true)
	check(_has(errs.messages, "missing audio file"), "missing sound file must fail")
	check(_has(errs.messages, "has no 'attack' sound"), "creature without a voice must fail (%s)" % m.id)
	data.audio.combat_log[&"play"] = &"no.such_sound"
	data.audio.screens[&"menu"] = {"music": "no_such_track", "ambience": ""}
	errs = ErrorLog.new()
	ContentValidator.validate(data, errs, false)
	check(_has(errs.messages, "unknown sound 'no.such_sound'"), "combat_log must point to a known sound")
	check(_has(errs.messages, "unknown music 'no_such_track'"), "screens must point to known music")
