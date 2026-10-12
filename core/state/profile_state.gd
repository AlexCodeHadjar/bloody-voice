class_name ProfileState
extends RefCounted
## Player settings that outlive a run (GDD 22.2): tutorial progress, hints on/off, volumes, full screen.
## Stored in user://profile.cfg, not in the run save, so a new run does not repeat the tutorial.

const SECTION := "profile"
const VERSION := 2  ## 2: full screen by default (owner, 2026-10-12)

var seen: PackedStringArray = []  ## tutorial sequences already shown
var hints_on: bool = true
var volume_master: float = 1.0  ## 0..1
var volume_music: float = 0.8
var volume_sounds: float = 1.0
var fullscreen: bool = true


func mark_seen(sequence: StringName) -> void:
	if not seen.has(String(sequence)):
		seen.append(String(sequence))


func has_seen(sequence: StringName) -> bool:
	return seen.has(String(sequence))


func reset_tutorial() -> void:
	seen = []
	hints_on = true


func to_config() -> ConfigFile:
	var c := ConfigFile.new()
	c.set_value(SECTION, "seen", seen)
	c.set_value(SECTION, "hints_on", hints_on)
	c.set_value(SECTION, "volume_master", volume_master)
	c.set_value(SECTION, "volume_music", volume_music)
	c.set_value(SECTION, "volume_sounds", volume_sounds)
	c.set_value(SECTION, "fullscreen", fullscreen)
	c.set_value(SECTION, "version", VERSION)
	return c


static func from_config(c: ConfigFile) -> ProfileState:
	var p := ProfileState.new()
	p.seen = PackedStringArray(c.get_value(SECTION, "seen", PackedStringArray()))
	p.hints_on = bool(c.get_value(SECTION, "hints_on", true))
	p.volume_master = clampf(float(c.get_value(SECTION, "volume_master", 1.0)), 0.0, 1.0)
	p.volume_music = clampf(float(c.get_value(SECTION, "volume_music", 0.8)), 0.0, 1.0)
	p.volume_sounds = clampf(float(c.get_value(SECTION, "volume_sounds", 1.0)), 0.0, 1.0)
	var old := int(c.get_value(SECTION, "version", 1)) < VERSION  # profiles from before: full screen once
	p.fullscreen = true if old else bool(c.get_value(SECTION, "fullscreen", true))
	return p


static func load_from(path: String) -> ProfileState:
	var c := ConfigFile.new()
	if c.load(path) != OK:
		return ProfileState.new()
	return from_config(c)


func save_to(path: String) -> Error:
	return to_config().save(path)
