class_name HeroCombatant
extends Combatant
## The hunter during a fight (GDD 4.2).

var sanity: int
var max_sanity: int
var ap: int
var max_ap: int
var ammo: int
var max_ammo: int
var hand_size: int
var cunning: int = 0
var agility: int = 0
var preview: int = 0  ## creature moves always visible ahead
var panicked: bool = false
var mods: Dictionary[StringName, int] = {}  ## passive gear bonuses (GearMods)


func mod(id: StringName) -> int:
	return mods.get(id, 0)
