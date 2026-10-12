class_name AudioDef
extends RefCounted
## Which sound plays on which game event (data/audio/sounds.json, GDD 24). Files live under res://audio/.

const ROOT := "res://audio/"
const BUSES: Array[StringName] = [&"UI", &"SFX", &"Music", &"Ambience"]


class SoundDef:
	var id: StringName
	var files: Array[String] = []  ## paths under res://audio/; a random one plays
	var db: float = 0.0
	var bus: StringName = &"SFX"
	var min_gap: float = 0.0  ## seconds before the same sound may play again


class TrackDef:
	var file: String
	var db: float = 0.0


var sounds: Dictionary[StringName, SoundDef] = {}
var music: Dictionary[StringName, TrackDef] = {}
var ambience: Dictionary[StringName, TrackDef] = {}
var screens: Dictionary[StringName, Dictionary] = {}  ## screen -> {music, ambience} ("" = silence)
var monster_events: Dictionary[StringName, SoundDef] = {}  ## select / attack / hit / idle / phase2
var combat_log: Dictionary[StringName, StringName] = {}  ## combat event kind -> sound id or monster.<event>


static func from_dict(d: Dictionary, errs: ErrorLog) -> AudioDef:
	var a := AudioDef.new()
	var w := "audio/sounds.json"
	var sounds := _objects(d, "sounds", errs, w)
	for key: String in sounds:
		a.sounds[StringName(key)] = _sound(StringName(key), sounds[key] as Dictionary, errs, w)
	var music := _objects(d, "music", errs, w)
	for key: String in music:
		a.music[StringName(key)] = _track(music[key] as Dictionary, errs, w + "/music/" + key)
	var ambience := _objects(d, "ambience", errs, w)
	for key: String in ambience:
		a.ambience[StringName(key)] = _track(ambience[key] as Dictionary, errs, w + "/ambience/" + key)
	var screens := _objects(d, "screens", errs, w)
	for key: String in screens:
		a.screens[StringName(key)] = screens[key] as Dictionary
	var voices := _objects(d, "monster_events", errs, w)
	for key: String in voices:
		a.monster_events[StringName(key)] = _sound(StringName(key), voices[key] as Dictionary, errs, w)
	for key: String in DefReader.dict(d, "combat_log", errs, w):
		if not key.begins_with("_"):
			a.combat_log[StringName(key)] = StringName(str(d["combat_log"][key]))
	return a


## The object entries of a section ("_comment" skipped); a non-object entry is a data error.
static func _objects(d: Dictionary, key: String, errs: ErrorLog, w: String) -> Dictionary:
	var out := {}
	var section := DefReader.dict(d, key, errs, w)
	for k: String in section:
		if k.begins_with("_"):
			continue
		if typeof(section[k]) != TYPE_DICTIONARY:
			errs.add("%s/%s/%s" % [w, key, k], "must be an object")
			continue
		out[k] = section[k]
	return out


static var _voice_cache: Dictionary[String, Array] = {}


## res:// paths of one creature's voice for an event ("attack" -> …/VIGIL_HOUND__attack_01.ogg, _02 …). Cached.
static func monster_files(monster: StringName, event: StringName) -> Array[String]:
	var cache_key := "%s/%s" % [monster, event]
	if _voice_cache.has(cache_key):
		var cached: Array[String] = []
		cached.assign(_voice_cache[cache_key])
		return cached
	var out: Array[String] = []
	var code := String(monster).to_upper()
	for i: int in range(1, 10):
		var path := "%smonsters/%s/%s__%s_%02d.ogg" % [ROOT, code, code, event, i]
		if not ResourceLoader.exists(path):
			break
		out.append(path)
	_voice_cache[cache_key] = out
	return out


static func _sound(id: StringName, d: Dictionary, errs: ErrorLog, w: String) -> SoundDef:
	var s := SoundDef.new()
	s.id = id
	for f: Variant in d.get("files", []):
		s.files.append(ROOT + str(f))
	s.db = DefReader.number(d, "db", errs, w + "/" + id, 0.0, false)
	s.bus = StringName(str(d.get("bus", "SFX")))
	s.min_gap = float(d.get("min_gap", 0.0))
	if not BUSES.has(s.bus):
		errs.add(w + "/" + id, "unknown bus '%s'" % s.bus)
	return s


static func _track(d: Dictionary, errs: ErrorLog, w: String) -> TrackDef:
	var t := TrackDef.new()
	t.file = ROOT + DefReader.string(d, "file", errs, w)
	t.db = DefReader.number(d, "db", errs, w, 0.0, false)
	return t
