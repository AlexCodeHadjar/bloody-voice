class_name StoryValidator
extends RefCounted
## Checks the district story (GDD 2.4): unique steps with a story letter, a known creature, slay or capture, a zone
## of the start district's map and a portrait; only the last step offers choices, whose factions exist.


static func validate(data: ContentData, errs: ErrorLog, check_files: bool) -> void:
	var st := data.story
	if st == null or st.steps.is_empty():
		errs.add("story/grey.json", "needs at least one step")
		return
	var map := data.district_map(data.balance.start_district)
	var seen: Array[StringName] = []
	for i: int in st.steps.size():
		var s := st.steps[i]
		var w := "story/grey.json/%s" % s.id
		if seen.has(s.id):
			errs.add(w, "duplicate step id")
		seen.append(s.id)
		var p := data.petition(s.petition)
		if p == null or not p.types.has(&"story"):
			errs.add(w, "petition '%s' must exist with type 'story'" % s.petition)
		if data.monster(s.monster) == null or not (s.type in [&"slay", &"capture"]):
			errs.add(w, "needs a known monster and type slay or capture")
		if map != null and not map.zones.any(func(z: DistrictMapDef.ZoneDef) -> bool: return z.id == s.zone):
			errs.add(w, "unknown zone '%s'" % s.zone)
		if check_files and not ResourceLoader.exists("res://art/ui/NPC__portrait__%s.webp" % s.portrait):
			errs.add(w, "missing portrait art/ui/NPC__portrait__%s.webp" % s.portrait)
		if not s.choices.is_empty() and i != st.steps.size() - 1:
			errs.add(w, "only the last step may offer choices")
		for c: StoryDefs.ChoiceDef in s.choices:
			for f: StringName in c.rep:
				if data.faction(f) == null:
					errs.add(w, "choice '%s': unknown faction '%s'" % [c.id, f])
