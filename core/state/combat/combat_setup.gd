class_name CombatSetup
extends RefCounted
## Everything needed to start a fight. Built by DeckBuilder.setup from the hunter's gear (or by tests).

var monster_id: StringName
var deck: Array[StringName] = []
var mods: Dictionary[StringName, int] = {}  ## passive gear bonuses (GearMods)
var hero_hp: int
var hero_max_hp: int
var max_sanity: int
var max_ap: int
var hand_size: int
var max_ammo: int
var cunning: int = 0
var capture_allowed: bool = false
var rng_seed: int = 0
