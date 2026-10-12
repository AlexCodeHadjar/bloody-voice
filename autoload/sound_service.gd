extends Node
## Plays the game's sounds (GDD 24): short sounds by id, creature voices, music and ambience per screen.
## What plays where is data (data/audio/sounds.json); screens call Sound.play(&"ui.click"), Sound.screen(&"city").

const POOL_SIZE := 10
const FADE := 1.2

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _zone: AudioStreamPlayer  ## second ambience layer: the zone under the camera (district map)
var _music_id: StringName = &"-"
var _ambience_id: StringName = &"-"
var _zone_id: StringName = &""
var _last_played: Dictionary[StringName, int] = {}  ## sound id -> msec
var _rng: RandomNumberGenerator
var _fades: Dictionary[AudioStreamPlayer, Tween] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: StringName in AudioDef.BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = _looping_player(&"Music")
	_ambience = _looping_player(&"Ambience")
	_zone = _looping_player(&"Ambience")
	_rng = Rng.stream(&"audio")


## A short sound by id from sounds.json (unknown ids are ignored, so a missing sound never breaks a screen).
func play(id: StringName) -> void:
	var def: AudioDef.SoundDef = _audio().sounds.get(id)
	if def != null and _ready_to_play(id, def.min_gap):
		_start(def.files, def.db, def.bus)


## The creature's own voice: event = select / attack / hit / idle / phase2.
func play_monster(monster: StringName, event: StringName) -> void:
	var def: AudioDef.SoundDef = _audio().monster_events.get(event)
	if def != null and _ready_to_play(StringName("%s.%s" % [monster, event]), def.min_gap):
		_start(AudioDef.monster_files(monster, event), def.db, &"SFX")


## Music and ambience of a screen (sounds.json/screens); the same track keeps playing across screens.
func screen(screen_id: StringName) -> void:
	var s: Dictionary = _audio().screens.get(screen_id, {})
	var music_id := StringName(str(s.get("music", "")))
	var amb_id := StringName(str(s.get("ambience", "")))
	if music_id != _music_id:
		_music_id = music_id
		_switch(_music, _audio().music.get(music_id) as AudioDef.TrackDef)
	if amb_id != _ambience_id:
		_ambience_id = amb_id
		_switch(_ambience, _audio().ambience.get(amb_id) as AudioDef.TrackDef)
	zone(&"")  # a screen starts without a zone layer; the district map adds its own


## Ambience of the place under the camera on top of the screen's own (fire by the tavern, cellars in the hollow).
func zone(ambience_id: StringName) -> void:
	if ambience_id == _zone_id:
		return
	_zone_id = ambience_id
	_switch(_zone, _audio().ambience.get(ambience_id) as AudioDef.TrackDef)


func _audio() -> AudioDef:
	return ContentDB.data.audio


func _ready_to_play(key: StringName, min_gap: float) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(key, -100000)) < int(min_gap * 1000.0):
		return false
	_last_played[key] = now
	return true


func _start(files: Array[String], db: float, bus: StringName) -> void:
	if files.is_empty():
		return
	var stream := load(files[_rng.randi_range(0, files.size() - 1)]) as AudioStream
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = db
	p.bus = bus
	p.play()


func _looping_player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	p.finished.connect(p.play)  # fallback loop for streams without a loop flag (WAV)
	return p


## Fade out -> swap -> fade in, as one tween per player; a new switch cancels the running one.
func _switch(player: AudioStreamPlayer, track: AudioDef.TrackDef) -> void:
	var old: Tween = _fades.get(player)
	if old != null:
		old.kill()
	var tween := create_tween()
	_fades[player] = tween
	if player.playing:
		tween.tween_property(player, "volume_db", -40.0, FADE)
	tween.tween_callback(_swap.bind(player, track))
	if track != null:
		tween.tween_property(player, "volume_db", track.db, FADE)


func _swap(player: AudioStreamPlayer, track: AudioDef.TrackDef) -> void:
	player.stop()
	if track == null:
		return
	var stream := load(track.file) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true  # seamless; `finished` -> play is the fallback for WAV
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	player.stream = stream
	player.volume_db = -40.0
	player.play()
