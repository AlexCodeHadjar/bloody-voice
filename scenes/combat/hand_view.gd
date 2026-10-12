class_name HandView
extends Control
## The hand as a fan at the bottom centre (GDD 21.2 zone 10). Card views are kept between redraws, so a hovered card keeps
## its tween; new cards fly in from the draw pile. The hovered or chosen card rises and grows x1.25.

signal card_chosen(uid: int)

const SIZE := Vector2(1100, 340)
const PITCH := 150.0
const HOVER_SCALE := 1.25
const DRAW_FROM := Vector2(-380, 220)  ## where drawn cards start (the draw pile corner)

var _views: Dictionary[int, CardView] = {}
var _order: Array[int] = []
var _hover_uid := 0
var _raised_uid := 0


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	TutorialAnchors.register(&"hand", self)


## `playable`: uid -> bool; `hints`: uids that glow as a hint (reload with an empty chamber).
func refresh(hand: Array[CardInstance], chosen_uid: int, playable: Dictionary[int, bool], hints: Array[int]) -> void:
	_raised_uid = chosen_uid
	var keep: Dictionary[int, bool] = {}
	_order.clear()
	for c: CardInstance in hand:
		keep[c.uid] = true
		_order.append(c.uid)
		var view: CardView = _views.get(c.uid)
		if view == null:
			view = CardView.new().setup(c)
			view.chosen.connect(card_chosen.emit)
			view.hovered.connect(_on_hovered)
			view.position = DRAW_FROM
			view.scale = Vector2(0.5, 0.5)
			add_child(view)
			_views[c.uid] = view
		view.set_state(playable.get(c.uid, false), c.uid == chosen_uid or hints.has(c.uid))
	for uid: int in _views.keys():
		if not keep.has(uid):
			_views[uid].queue_free()
			_views.erase(uid)
	_layout()


func view_of(uid: int) -> CardView:
	return _views.get(uid)


func _on_hovered(uid: int, on: bool) -> void:
	if on:
		_hover_uid = uid
	elif _hover_uid == uid:
		_hover_uid = 0
	_layout()


func _layout() -> void:
	var n := _order.size()
	var pitch := minf(PITCH, (SIZE.x - 260.0) / float(maxi(n - 1, 1)))
	for i: int in n:
		var view: CardView = _views[_order[i]]
		var t := float(i) - float(n - 1) / 2.0
		var raised := _order[i] == _hover_uid or _order[i] == _raised_uid
		view.z_index = 20 if _order[i] == _hover_uid else (10 if raised else 0)
		var center := Vector2(SIZE.x / 2.0 + t * pitch, 205.0 + t * t * 5.0)
		var rot := deg_to_rad(t * 3.0)
		if raised:
			center.y = SIZE.y - CardView.SIZE.y * HOVER_SCALE / 2.0 - 5.0
			rot = 0.0
		var fresh := view.position == DRAW_FROM
		view.go_to(center - CardView.SIZE / 2.0, rot, HOVER_SCALE if raised else 1.0, 0.35 if fresh else 0.16)
