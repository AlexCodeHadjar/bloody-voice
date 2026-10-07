extends Node
## Developer auto-screenshots. Does nothing unless started with:
##   Godot --path . --resolution 1920x1080 -- --shots=<absolute dir>
## Plays a fixed scripted route and saves PNGs for visual review (GDD 19.6).

const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"

var _dir := ""


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_dir = arg.trim_prefix("--shots=")
	if _dir != "":
		DirAccess.make_dir_recursive_absolute(_dir)
		_run.call_deferred()


func _run() -> void:
	await _wait(1.5)
	await _shot("01_main_menu")
	GameState.new_game(1)
	get_tree().change_scene_to_file(CITY_MAP)
	await _wait(1.5)
	await _shot("02_city_map")
	var view := get_tree().current_scene.find_child("*MapView*", true, false) as MapView
	if view == null:
		for n: Node in get_tree().current_scene.find_children("*", "Control", true, false):
			if n is MapView:
				view = n as MapView
	if view != null:
		_hover(view, &"LUMEN")
		await _wait(0.5)
		await _shot("03_hover_lumen")
		GameState.move_hero(&"SCARLET")
		_hover(view, &"SCARLET")
		await _wait(0.5)
		await _shot("04_hero_in_scarlet")
	get_tree().quit()


func _hover(view: MapView, district: StringName) -> void:
	var region := MapRegionRules.home_region(ContentDB.data.map_regions, district)
	var ev := InputEventMouseMotion.new()
	ev.position = view.image_to_global(region.center)
	ev.global_position = ev.position
	get_viewport().push_input(ev)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_dir.path_join(shot_name + ".png"))
