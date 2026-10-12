extends Node
## The player profile (ProfileState in user://profile.cfg): settings screen and tutorial read and change it here.
## Applies volumes to the audio buses (created by Sound) and the window mode.

const PATH := "user://profile.cfg"
const MUTE_DB := -80.0

var state: ProfileState = ProfileState.new()


func _ready() -> void:
	state = ProfileState.load_from(PATH)
	apply()


func save() -> void:
	state.save_to(PATH)


func apply() -> void:
	apply_volumes()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if state.fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED)


func apply_volumes() -> void:
	_bus_volume(&"Master", state.volume_master)
	_bus_volume(&"Music", state.volume_music)
	_bus_volume(&"Ambience", state.volume_music)
	_bus_volume(&"SFX", state.volume_sounds)
	_bus_volume(&"UI", state.volume_sounds)


## save = false while a slider is dragged (the panel saves on release and on close).
func set_volume(which: StringName, value: float, save_now: bool = true) -> void:
	match which:
		&"master":
			state.volume_master = clampf(value, 0.0, 1.0)
		&"music":
			state.volume_music = clampf(value, 0.0, 1.0)
		&"sounds":
			state.volume_sounds = clampf(value, 0.0, 1.0)
	apply_volumes()
	if save_now:
		save()


func set_fullscreen(on: bool) -> void:
	state.fullscreen = on
	apply()
	save()


func set_hints(on: bool) -> void:
	state.hints_on = on
	save()


func reset_tutorial() -> void:
	state.reset_tutorial()
	save()


func _bus_volume(bus: StringName, value: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(value) if value > 0.001 else MUTE_DB)
