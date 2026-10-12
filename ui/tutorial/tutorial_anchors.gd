class_name TutorialAnchors
extends RefCounted
## Elements a tutorial hint can light up (GDD 22.4). Screens register their nodes by id; the overlay asks for the
## current screen rectangle every frame, so a moving element (a scrolled map, a rebuilt hand) stays lit.

static var _nodes: Dictionary[StringName, WeakRef] = {}


static func register(id: StringName, node: Control) -> void:
	_nodes[id] = weakref(node)


## The element still exists (its screen was not left).
static func alive(id: StringName) -> bool:
	var ref: WeakRef = _nodes.get(id)
	var node := ref.get_ref() as Control if ref != null else null
	return node != null and node.is_inside_tree()


## Screen rectangle of the element, or an empty Rect2 when it is gone or hidden.
static func rect(id: StringName) -> Rect2:
	var ref: WeakRef = _nodes.get(id)
	var node := ref.get_ref() as Control if ref != null else null
	if node == null or not node.is_inside_tree() or not node.is_visible_in_tree():
		return Rect2()
	return node.get_global_rect()
