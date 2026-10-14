extends Node
## Developer auto-screenshots. Does nothing unless started with:
##   Godot --path . --resolution 1920x1080 -- --shots=<absolute dir>
## Plays a fixed scripted route and saves PNGs for visual review (GDD 19.6).

const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"
const COMBAT := "res://scenes/combat/combat_screen.tscn"
const EQUIPMENT := "res://scenes/equipment/equipment_screen.tscn"
const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"
const WORKSHOP := "res://scenes/workshop/workshop_screen.tscn"

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
	await _district_shots()
	await _contract_shots()
	await _rumor_shots()
	await _shop_shots()
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
		_hover(view, &"SCARLET")
		await _wait(0.5)
		await _shot("04_hover_locked")
	await _workshop_shots()
	get_tree().change_scene_to_file("res://scenes/skills/skill_web_screen.tscn")
	await _wait(1.0)
	await _shot("28_skill_web")
	await _equipment_shots()
	await _combat_shots()
	get_tree().quit()


## The district map (GDD 20): start at home, walk to the Rusty Cog, its card, then the calibration overlay (F3).
func _district_shots() -> void:
	get_tree().change_scene_to_file(DISTRICT)
	await _wait(2.0)
	await _shot("11_district_map")
	var screen := get_tree().current_scene
	var map := ContentDB.data.district_map(GameState.run.hero_district)
	screen.call("_on_landmark_clicked", map.landmark(&"rusty_cog"))
	await _wait(0.8)
	await _shot("12_district_walk")
	await _wait(2.5)
	await _shot("13_district_card")
	for n: Node in screen.find_children("*", "Control", true, false):
		if n is DistrictView:
			var v := n as DistrictView
			v.overlay.toggle_debug()
			v.call("_zoom_at", v.size * 0.5, 0.1)
			v.center_on(map.node_pos(&"square"))
	await _wait(0.5)
	await _shot("14_district_calibration")


## Contracts (GDD 7): the tavern board, a tablet, then the taken contract in the tracker with its zone glowing.
func _contract_shots() -> void:
	get_tree().change_scene_to_file(DISTRICT)
	await _wait(1.5)
	var screen := get_tree().current_scene
	screen.call("_on_action", &"tavern")
	await _wait(0.8)
	await _shot("15_contract_board")
	var board: ContractBoard = null
	for n: Node in screen.get_children():
		if n is ContractBoard:
			board = n as ContractBoard
	var leaflets := ContractRules.board(GameState.run.contracts)
	if board == null or leaflets.is_empty():
		return
	board.open_tablet(leaflets, 0)
	await _wait(0.6)
	await _shot("16_contract_tablet")
	GameState.accept_contract(leaflets[0].uid)
	await _wait(0.6)
	await _shot("17_contract_taken")
	board.close_board()
	await _wait(0.3)
	screen.call("_on_zone_requested", leaflets[0].zone)
	await _wait(1.2)
	await _shot("18_contract_tracker_zone")


## Rumors (GDD 8.4): listening in the hunter's zone, a heard rumor, a mark with its sheet.
func _rumor_shots() -> void:
	var screen := get_tree().current_scene
	var listen: ListenLayer = screen.get("_listen")
	var panels: DistrictPanels = screen.get("_panels")
	if listen == null:
		return
	var left := panels.current  # the contract tablet of the shots before
	if left != null:
		left.emit_signal(&"closed")
		left.queue_free()
	await _wait(0.3)
	screen.call("_to_hero")
	listen.toggle()
	await _wait(3.5)
	await _shot("19_rumor_listening")
	var zone := DistrictMapRules.zone_at(ContentDB.data.district_map(GameState.run.hero_district),
		(screen.get("_hero") as HeroWalker).position)
	var h := GameState.hear_rumor(zone, [])
	if h == null:
		return
	panels.open_heard(h)
	await _wait(0.6)
	await _shot("20_rumor_sheet")
	(panels.current as RumorSheet).close_sheet()
	listen.stop()
	for i: int in 30:  # take rumors until a mark comes out (a creature's or a threat)
		var t := GameState.take_rumor(GameState.hear_rumor(zone, []))
		if t != null and t.mark != null:
			(screen.get("_view") as DistrictView).center_on(ContentDB.data.district_map(GameState.run.hero_district).node_pos(t.mark.node))
			await _wait(0.6)
			await _shot("21_rumor_mark")
			panels.open_mark(t.mark.uid)
			break
	await _wait(0.6)
	await _shot("21_rumor_mark_sheet")
	if panels.current is MarkSheet:
		(panels.current as MarkSheet).close_sheet()


## The shop, a tavern shift, the infirmary and the Scriptorium (GDD 11.1, 3.3, 4).
func _shop_shots() -> void:
	var screen := get_tree().current_scene
	screen.call("_on_action", &"shop")
	await _wait(0.8)
	await _shot("24_shop")
	for n: Node in screen.get_children():
		if n is ShopTable:
			(n as ShopTable).close_shop()
	await _wait(0.3)
	screen.call("_on_action", &"shift")
	await _wait(0.8)
	await _shot("25_tavern_shift")
	for n: Node in screen.get_children():
		if n is ShiftPanel:
			(n as ShiftPanel).close_panel()
	for place: Array in [[&"infirmary", "26_infirmary"], [&"library", "27_scriptorium"]]:
		await _wait(0.3)
		screen.call("_on_action", place[0])
		await _wait(0.6)
		await _shot(place[1] as String)
		for n: Node in screen.get_children():
			if n is PlacePanel:
				(n as PlacePanel).close_panel()


## Workshop (GDD 23.1): the start, then a blueprint picked on the workbench after a craft.
func _workshop_shots() -> void:
	get_tree().change_scene_to_file(WORKSHOP)
	await _wait(1.0)
	await _shot("22_workshop")
	GameState.craft_item(&"bayonet_mount")
	get_tree().current_scene.call("_pick", &"bayonet_mount")
	await _wait(0.5)
	await _shot("23_workshop_crafted")


func _equipment_shots() -> void:
	get_tree().change_scene_to_file(EQUIPMENT)
	await _wait(1.0)
	await _shot("09_equipment_start")
	GameState.dev_grant_all_gear()
	GameState.set_socket(&"helmet", 0, &"lantern_of_revealing")
	GameState.equip_module(&"drum_magazine", &"magazine", Vector2i.ZERO, 0)
	GameState.equip_module(&"bayonet_mount", &"stock", Vector2i.ZERO, 1)
	get_tree().current_scene.call("_hold", &"rifled_barrel")
	await _wait(0.5)
	await _shot("10_equipment_built")


func _combat_shots() -> void:
	GameState.run.open_districts.append(&"NORDHAL")  # dev run only: unlock the district the shots use (bypasses GameState on purpose)
	GameState.move_hero(&"NORDHAL")
	GameState.start_hunt(&"vigil_hound")
	get_tree().change_scene_to_file(COMBAT)
	await _wait(1.0)
	await _shot("05_combat_start")
	var s := GameState.combat
	for c: CardInstance in s.hand:
		if c.def.target == &"enemy_or_part":
			get_tree().current_scene.call("_on_card_chosen", c.uid)
			break
	await _wait(0.3)
	await _shot("06_combat_targeting")
	get_tree().current_scene.call("_on_target", CombatTarget.part(&"jaw"))
	GameState.combat_end_turn()
	await _wait(0.3)
	await _shot("07_combat_turn_2")
	s.enemy.hp = mini(s.enemy.hp, 5)  # the result shot shows a win: the creature's cracked silhouette
	while not s.is_over():
		CombatBot.play_turn(s, ContentDB.data)
	EventBus.combat_updated.emit()
	await _wait(0.5)
	await _shot("08_combat_result")


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
	_check_panels(get_tree().current_scene)


## Panels over the district fill the screen; a 0×0 one draws in the corner without its shade (check_all greps "error").
func _check_panels(root: Node) -> void:
	if root == null:
		return
	var screen := get_viewport().get_visible_rect().size
	for n: Node in root.find_children("*", "Control", true, false):
		if (n is ContractBoard or n is ContractTablet or n is RumorSheet or n is MarkSheet or n is ShopTable
				or n is ShiftPanel or n is PlacePanel) and not (n as Control).size.is_equal_approx(screen):
			push_error("panel %s is %s, not the screen %s" % [(n.get_script() as Script).get_global_name(), (n as Control).size, screen])
