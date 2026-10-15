class_name RumorValidator
extends RefCounted
## Checks rumor content (GDD 8): witnesses exist, every zone of a district map with creatures has pictures and
## known tags, the pictures exist, the balance numbers make sense.


static func validate(data: ContentData, errs: ErrorLog, check_files: bool) -> void:
	var w := "rumors/rumors.json"
	if data.rumor_data.witnesses.is_empty():
		errs.add(w, "needs at least one witness")
	for district: StringName in data.rumor_data.zones:
		var map := data.district_map(district)
		if map == null:
			errs.add(w, "zones: no district map '%s'" % district)
			continue
		for zone_id: StringName in data.rumor_data.zones[district]:
			if map.zone(zone_id) == null:
				errs.add(w, "zones/%s: unknown zone '%s'" % [district, zone_id])
	for map: DistrictMapDef in data.district_maps.values():
		if EncounterRules.pool(data, map.district).is_empty():
			continue
		for z: DistrictMapDef.ZoneDef in map.zones:
			_zone(data, map.district, z.id, errs, check_files)
	_balance(data.balance.rumors, errs)


static func _zone(data: ContentData, district: StringName, zone_id: StringName, errs: ErrorLog, check_files: bool) -> void:
	var w := "rumors/rumors.json/zones/%s/%s" % [district, zone_id]
	var z := data.rumor_data.zone(district, zone_id)
	if z == null:
		errs.add(w, "every zone of a district with creatures needs rumor pictures and tags")
		return
	if z.art.is_empty():
		errs.add(w, "needs at least one picture")
	for a: StringName in z.art:
		if check_files and not ResourceLoader.exists(RumorDefs.ART_DIR % a):
			errs.add(w, "missing art %s" % (RumorDefs.ART_DIR % a))
	for t: StringName in z.tags:
		if not data.tags.has(t):
			errs.add(w, "tag '%s' is not in contracts/tags.json" % t)


static func _balance(b: RumorDefs.Balance, errs: ErrorLog) -> void:
	var w := "balance.json/rumors"
	for pair: Array in [[b.true_tags_min, b.true_tags_max], [b.lie_tags_min, b.lie_tags_max], [b.ask_min, b.ask_max]]:
		if int(pair[0]) < 1 or int(pair[1]) < int(pair[0]):
			errs.add(w, "every *_min must be >= 1 and <= its *_max")
	if b.overhear_steps < 1 or b.overhear_per_day < 0 or b.notebook_max < 1 or b.trail_needed < 1:
		errs.add(w, "overhear_steps, notebook_max and trail_needed must be >= 1, overhear_per_day >= 0")
	for c: float in [b.overhear_chance, b.true_chance, b.wrong_creature_chance, b.noise_chance]:
		if c < 0.0 or c > 1.0:
			errs.add(w, "overhear_chance, true_chance, wrong_creature_chance and noise_chance must be in 0..1")
