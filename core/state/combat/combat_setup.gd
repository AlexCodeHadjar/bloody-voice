class_name CombatSetup
extends RefCounted
## Everything needed to start a fight. Built by DeckBuilder.setup from the hunter's gear (or by tests).

var monster_id: StringName
var deck: Array[StringName] = []
var mods: Dictionary[StringName, int] = {}  ## passive gear bonuses (GearMods)
var hero_hp: int
var hero_max_hp: int
var max_sanity: int
var hero_sanity: int = -1  ## Sanity at the start (carried from the last fight); -1 = full
var max_ap: int
var hand_size: int
var max_ammo: int
var cunning: int = 0
var agility: int = 0  ## dodge chance per point (GDD 4.1)
var preview: int = 0  ## creature moves always visible ahead (Cunning)
var capture_allowed: bool = false
var rng_seed: int = 0
var backdrop: String = ""  ## res:// path of the fight's background picture ("" = none)
var contract_uid: int = 0  ## the contract this fight counts for (0 = none, GDD 7)
var enemy_hp_mult: float = 1.0  ## > 1 when the contract is overdue: the creature got stronger
var enemy_damage_bonus: int = 0  ## added to every hit of the creature (overdue contract)
