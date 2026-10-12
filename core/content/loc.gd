class_name Loc
extends RefCounted
## Game text by key from locale/strings.csv (GDD 22.5). Russian is the game language; English comes later.
##   Loc.t("ui.combat.end_turn")                      -> «Конец хода»
##   Loc.t("effect.draw", {"n": 2})                   -> «взять 2 карты»
## Placeholders: {name} is replaced by args[name]; {n:карту|карты|карт} picks the Russian plural form for args[n].
## A missing key returns the key itself, so it is visible on screen (tests fail on missing keys).

const LOCALE := "ru"

static var _plural_re: RegEx
static var _arg_re: RegEx


## Makes the engine use the game locale (Controls with auto-translate, number formatting).
static func apply_locale() -> void:
	TranslationServer.set_locale(LOCALE)


static func has(key: String) -> bool:
	return _raw(key) != ""


static func t(key: String, args: Dictionary = {}) -> String:
	var text := _raw(key)
	if text == "":
		return key
	return format(text, args)


## Text of key, or `fallback` when the table has no such key (content names before they are translated).
static func or_default(key: String, fallback: String, args: Dictionary = {}) -> String:
	var text := _raw(key)
	return format(text, args) if text != "" else fallback


static func format(text: String, args: Dictionary) -> String:
	if not text.contains("{"):
		return text
	_compile()
	for m: RegExMatch in _plural_re.search_all(text):
		var forms := m.get_string(2).split("|")
		var n := int(args.get(m.get_string(1), 0))
		text = text.replace(m.get_string(0), forms[mini(plural_index(n), forms.size() - 1)])
	for m: RegExMatch in _arg_re.search_all(text):
		if args.has(m.get_string(1)):
			text = text.replace(m.get_string(0), str(args[m.get_string(1)]))
	return text


## Russian plural form: 0 = 1, 21, 31… (карту); 1 = 2–4, 22–24… (карты); 2 = 0, 5–20, 25–30… (карт).
static func plural_index(n: int) -> int:
	var a := absi(n)
	if a % 10 == 1 and a % 100 != 11:
		return 0
	if a % 10 >= 2 and a % 10 <= 4 and (a % 100 < 12 or a % 100 > 14):
		return 1
	return 2


## Placeholder names used in a text: "{n} {n:a|b|c} {card}" -> ["n", "card"].
static func placeholders(text: String) -> PackedStringArray:
	_compile()
	var out: PackedStringArray = []
	for re: RegEx in [_plural_re, _arg_re]:
		for m: RegExMatch in re.search_all(text):
			if not out.has(m.get_string(1)):
				out.append(m.get_string(1))
	return out


static func _raw(key: String) -> String:
	var translation := TranslationServer.get_translation_object(LOCALE)
	if translation == null:
		return ""
	return String(translation.get_message(StringName(key)))


static func _compile() -> void:
	if _plural_re != null:
		return
	_plural_re = RegEx.create_from_string("\\{(\\w+):([^}]*)\\}")
	_arg_re = RegEx.create_from_string("\\{(\\w+)\\}")
