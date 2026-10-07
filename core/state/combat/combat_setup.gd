class_name CombatSetup
extends RefCounted
## Everything needed to start a fight. Built by GameState (or tests / bots) from the run.

var monster_id: StringName
var deck: Array[StringName] = []
var hero_hp: int
var hero_max_hp: int
var max_sanity: int
var max_ap: int
var hand_size: int
var max_ammo: int
var cunning: int = 0
var capture_allowed: bool = false
var rng_seed: int = 0


## Default hunter from balance.json (until the run tracks the hero's own stats).
static func from_balance(b: BalanceDef, monster: StringName, seed_value: int) -> CombatSetup:
	var s := CombatSetup.new()
	s.monster_id = monster
	s.deck = b.starter_deck.duplicate()
	s.hero_hp = b.base_hp
	s.hero_max_hp = b.base_hp
	s.max_sanity = b.base_sanity
	s.max_ap = b.base_ap
	s.hand_size = b.hand_size
	s.max_ammo = b.max_ammo
	s.rng_seed = seed_value
	return s
