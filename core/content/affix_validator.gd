class_name AffixValidator
extends RefCounted
## Checks creature affixes (GDD 17): unique ids, a known sign, a sane HP multiplier and weight, a move with valid
## effects whose id no creature uses, and the threat numbers.


static func validate(data: ContentData, errs: ErrorLog) -> void:
	var seen: Array[StringName] = []
	for a: AffixDefs.AffixDef in data.affixes:
		var w := "affixes/affixes.json/%s" % a.id
		if seen.has(a.id):
			errs.add(w, "duplicate affix id")
		seen.append(a.id)
		if not data.tags.has(a.tag):
			errs.add(w, "tag '%s' is not in contracts/tags.json" % a.tag)
		if a.hp_mult < 1.0 or a.weight <= 0.0:
			errs.add(w, "hp_mult must be >= 1 and weight > 0")
		for e: Dictionary in a.move.effects:
			var problem := EffectSchema.check(e)
			if problem != "":
				errs.add(w + "/move", problem)
		for id: StringName in data.monster_order:
			var m := data.monster(id)
			if m != null and m.moves.has(a.move.id):
				errs.add(w + "/move", "move id '%s' is used by %s" % [a.move.id, id])
	var b := data.balance.affixes
	if b.per_week < 0.0 or b.per_rank < 0.0 or b.max_affixes < 0 or b.max_affixes > data.affixes.size():
		errs.add("balance.json/affixes", "per_week, per_rank >= 0; max between 0 and the number of affixes")
