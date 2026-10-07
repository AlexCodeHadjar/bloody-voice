class_name GearMods
extends RefCounted
## Passive bonuses that modules and mechanisms give in combat (GDD 5). Values add up across all gear.

const ALL: Array[StringName] = [
	&"max_ammo",          # + magazine size
	&"max_hp",            # + hunter max HP
	&"shot_damage",       # + damage of cards that use ammo
	&"part_damage",       # + damage of shots aimed at a body part
	&"shot_block",        # gain block whenever a card that uses ammo is played
	&"shot_bleed",        # cards that use ammo also apply this much Bleed
	&"bleed_bonus",       # Bleed the hunter applies is this much stronger
	&"reload_draw",       # Reload also draws this many cards
	&"first_turn_draw",   # first turn: draw more
	&"first_turn_ap",     # first turn: more AP
	&"foresight_start",   # first turn: see the creature's next moves
	&"rage_hp_discount",  # Rage cards cost this much less HP
]


static func sum(into: Dictionary[StringName, int], add: Dictionary[StringName, int]) -> void:
	for k: StringName in add:
		into[k] = int(into.get(k, 0)) + add[k]


static func read(d: Dictionary, errs: ErrorLog, where: String) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	var raw := DefReader.dict(d, "mods", errs, where, false)
	for k: Variant in raw:
		var id := StringName(str(k))
		if not ALL.has(id):
			errs.add(where, "unknown mod '%s'" % id)
		out[id] = int(raw[k])
	return out
