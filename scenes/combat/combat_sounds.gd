class_name CombatSounds
extends Node
## Turns new combat log events into sounds (data/audio/sounds.json/combat_log, GDD 24): card plays, hits,
## the creature's own voice on its attacks, phase change and pain. Several events of one update play in a short row.

const STEP := 0.14  ## seconds between sounds of one update
const MAX_PER_UPDATE := 4

const PRIORITY: Array[StringName] = [&"won", &"lost", &"phase", &"part_broken"]  ## never dropped

var _seen := 0
var _fight: CombatState


func _ready() -> void:
	EventBus.combat_updated.connect(_on_update)
	_on_update()


func _on_update() -> void:
	var s := GameState.combat
	if s == null:
		return
	if s != _fight:  # a new fight
		_fight = s
		_seen = 0
	var cues: Array[String] = []
	var late: Array[String] = []  ## priority cues that come after the first few
	for i: int in range(_seen, s.events.size()):
		var cue := _cue(s.events[i])
		if cue == "" or cues.has(cue) or late.has(cue):
			continue
		if cues.size() < MAX_PER_UPDATE:
			cues.append(cue)
		elif PRIORITY.has(s.events[i].kind):
			late.append(cue)
	cues.append_array(late)
	_seen = s.events.size()
	for i: int in cues.size():
		get_tree().create_timer(STEP * i).timeout.connect(_play.bind(cues[i], s.enemy.def.id))


func _cue(e: CombatEvent) -> String:
	var kind := e.kind
	if kind == &"damage":
		kind = &"damage_hero" if e.subject == &"hero" else &"damage_enemy"
	return String(ContentDB.data.audio.combat_log.get(kind, &""))


func _play(cue: String, monster: StringName) -> void:
	if cue.begins_with("monster."):
		UiKit.monster_sound(monster, StringName(cue.trim_prefix("monster.")))
	else:
		UiKit.sound(StringName(cue))
