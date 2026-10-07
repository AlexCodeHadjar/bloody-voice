class_name CombatState
extends RefCounted
## The whole fight as data. Changed only by core/rules/combat; screens read it.

enum Phase { PLAYER, ENEMY, WON, LOST }

var phase: Phase = Phase.PLAYER
var turn: int = 0
var hero: HeroCombatant = HeroCombatant.new()
var enemy: EnemyCombatant = EnemyCombatant.new()

var draw_pile: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var exhaust_pile: Array[CardInstance] = []
var next_uid: int = 1

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var capture_allowed: bool = false
var foresight: bool = false
var captured: bool = false
var escaped: bool = false
var trophies: Array[StringName] = []
var events: Array[CombatEvent] = []


func is_over() -> bool:
	return phase == Phase.WON or phase == Phase.LOST


func log_event(kind: StringName, text: String, amount: int = 0, subject: StringName = &"") -> void:
	events.append(CombatEvent.create(kind, text, amount, subject))


func find_in_hand(uid: int) -> CardInstance:
	for c: CardInstance in hand:
		if c.uid == uid:
			return c
	return null


func outcome() -> StringName:
	if phase == Phase.WON:
		return &"captured" if captured else &"slain"
	if phase == Phase.LOST:
		return &"escaped" if escaped else &"fallen"
	return &"ongoing"
