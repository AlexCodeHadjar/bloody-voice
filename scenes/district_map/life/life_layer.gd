class_name LifeLayer
extends Node2D
## All the life of a district map (map-life-people.md): passers-by, local characters, animals, standing scenes and
## effects, sorted by their feet (y). Atmosphere only: nothing here touches the game state.

const CHAT_CHECK := 0.5  ## seconds between looks for two walkers who met
const CHAT_DISTANCE := 60.0
const EMOTES: Array[int] = [1, 2, 3, 8]  ## note, coin, heart, eye

var hero: Node2D = null:
	set(value):
		hero = value
		if _ctx != null:
			_ctx.hero = value

var _ctx: LifeContext
var _residents: Array[Resident] = []
var _check_in := CHAT_CHECK


func setup(map: DistrictMapDef, data: ContentData) -> void:
	var life := data.life(map.district)
	if life == null:
		return
	y_sort_enabled = true
	_ctx = LifeContext.new()
	_ctx.map = map
	_ctx.life = life
	_ctx.rng = Rng.stream(&"life")
	_ctx.hero = hero
	for id: StringName in map.nodes:
		_ctx.node_ids.append(id)
	_residents = LifeSpawn.build(self, _ctx)


## F3 markup changed the residents: build them again from the edited data.
func rebuild(map: DistrictMapDef, data: ContentData) -> void:
	for c: Node in get_children():
		c.queue_free()
	_residents.clear()
	setup(map, data)


func _process(delta: float) -> void:
	_check_in -= delta
	if _check_in > 0.0:
		return
	_check_in = CHAT_CHECK
	_meet()


## Two walkers who pass each other stop for a chat; one of them shows an emote.
func _meet() -> void:
	for i: int in _residents.size():
		var a := _residents[i]
		if not a.can_chat():
			continue
		for j: int in range(i + 1, _residents.size()):
			var b := _residents[j]
			if b.can_chat() and a.position.distance_to(b.position) < CHAT_DISTANCE:
				var rng := _ctx.rng
				var secs := rng.randf_range(3.0, 8.0)
				var emote := EMOTES[rng.randi_range(0, EMOTES.size() - 1)]
				a.start_chat(b.position, secs, emote)
				b.start_chat(a.position, secs, 0)
				break
