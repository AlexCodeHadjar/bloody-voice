class_name AudioValidator
extends RefCounted
## Checks data/audio/sounds.json against the files in res://audio/ and the creatures (GDD 24).


static func validate(data: ContentData, errs: ErrorLog, check_files: bool) -> void:
	var a := data.audio
	var w := "audio/sounds.json"
	for key: StringName in a.combat_log:
		var target := String(a.combat_log[key])
		var ok := a.monster_events.has(StringName(target.trim_prefix("monster."))) if target.begins_with("monster.") \
			else a.sounds.has(StringName(target))
		if not ok:
			errs.add(w + "/combat_log/" + key, "unknown sound '%s'" % target)
	for screen: StringName in a.screens:
		var s: Dictionary = a.screens[screen]
		if str(s.get("music", "")) != "" and not a.music.has(StringName(str(s["music"]))):
			errs.add(w + "/screens/" + screen, "unknown music '%s'" % s["music"])
		if str(s.get("ambience", "")) != "" and not a.ambience.has(StringName(str(s["ambience"]))):
			errs.add(w + "/screens/" + screen, "unknown ambience '%s'" % s["ambience"])
	if check_files:
		_files(data, errs, w)


static func _files(data: ContentData, errs: ErrorLog, w: String) -> void:
	var a := data.audio
	for s: AudioDef.SoundDef in a.sounds.values():
		if s.files.is_empty():
			errs.add(w + "/sounds/" + s.id, "no files")
		for f: String in s.files:
			if not ResourceLoader.exists(f):
				errs.add(w + "/sounds/" + s.id, "missing audio file %s" % f)
	for t: AudioDef.TrackDef in a.music.values() + a.ambience.values():
		if not ResourceLoader.exists(t.file):
			errs.add(w, "missing audio file %s" % t.file)
	for m: StringName in data.monster_order:
		for ev: StringName in a.monster_events:
			if AudioDef.monster_files(m, ev).is_empty():
				errs.add(w + "/monster_events", "creature %s has no '%s' sound (res://audio/monsters/)" % [m, ev])
