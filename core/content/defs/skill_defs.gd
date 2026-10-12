class_name SkillDefs
extends RefCounted
## Skill webs (data/skills/*.json, GDD 4.4, 23.2): nodes with a type, a place on the web, links and an effect;
## and the "skills" block of balance.json.

const TYPES: Array[StringName] = [&"start", &"passive", &"blueprint", &"socket", &"keystone"]


class NodeDef:
	var id: StringName
	var type: StringName
	var dir: StringName  ## gear / weapon / modules / mechanisms ("" for the start)
	var pos: Vector2  ## grid position on the web (x right, y down)
	var links: Array[StringName] = []
	var name: String
	var text: String
	var mods: Dictionary[StringName, int] = {}
	var blueprint: StringName = &""
	var socket: StringName = &""  ## armor piece that gets +1 socket
	var sockets_all: int = 0
	var crafts: int = 0
	var cards: Array[StringName] = []  ## added to every fight's deck while owned (Monster web)
	var blood_cells: Dictionary[StringName, Array] = {}  ## section -> Array of Vector2i turned into blood cells
	var sample: StringName = &""  ## creature whose blood sample the node uses up ("" = none)
	var pure: bool = false  ## needs a pure sample (from a capture)
	var voice: int = 0  ## how much the Voice grows


class WebDef:
	var id: StringName
	var nodes: Dictionary[StringName, NodeDef] = {}
	var order: Array[StringName] = []

	func node(node_id: StringName) -> NodeDef:
		return nodes.get(node_id) as NodeDef


class Balance:
	var node_cost: int = 1
	var reset_cost_per_point: int = 15


static func web(d: Dictionary, errs: ErrorLog, file: String) -> WebDef:
	var x := WebDef.new()
	x.id = DefReader.id(d, "web", errs, file)
	for v: Variant in DefReader.array(d, "nodes", errs, file):
		var nd := _node(v as Dictionary, errs, "%s/%s" % [file, x.id])
		if x.nodes.has(nd.id):
			errs.add(file, "duplicate node '%s'" % nd.id)
		x.nodes[nd.id] = nd
		x.order.append(nd.id)
	return x


static func _node(d: Dictionary, errs: ErrorLog, w: String) -> NodeDef:
	var nd := NodeDef.new()
	nd.id = DefReader.id(d, "id", errs, w)
	var nw := "%s/%s" % [w, nd.id]
	nd.type = DefReader.id(d, "type", errs, nw)
	nd.dir = DefReader.id(d, "dir", errs, nw, false)
	var pos := DefReader.array(d, "pos", errs, nw)
	nd.pos = Vector2(float(pos[0]), float(pos[1])) if pos.size() == 2 else Vector2.ZERO
	nd.links = DefReader.ids(d, "links", errs, nw)
	nd.name = DefReader.string(d, "name", errs, nw)
	nd.text = DefReader.string(d, "text", errs, nw)
	var e := DefReader.dict(d, "effect", errs, nw)
	nd.mods = GearMods.read(e, errs, nw)
	nd.blueprint = DefReader.id(e, "blueprint", errs, nw, false)
	nd.socket = DefReader.id(e, "socket", errs, nw, false)
	nd.sockets_all = DefReader.integer(e, "sockets_all", errs, nw, 0, false)
	nd.crafts = DefReader.integer(e, "crafts", errs, nw, 0, false)
	nd.cards = DefReader.ids(e, "cards", errs, nw)
	var blood := DefReader.dict(e, "blood_cells", errs, nw, false)
	for s: Variant in blood:
		var cells: Array[Vector2i] = []
		for c: Variant in blood[s] as Array:
			var xy := c as Array
			cells.append(Vector2i(int(xy[0]), int(xy[1])) if xy.size() == 2 else Vector2i(-1, -1))
		nd.blood_cells[StringName(str(s))] = cells
	nd.sample = DefReader.id(d, "sample", errs, nw, false)
	nd.pure = DefReader.flag(d, "pure")
	nd.voice = DefReader.integer(d, "voice", errs, nw, 0, false)
	return nd


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	b.node_cost = DefReader.integer(d, "node_cost", errs, "balance.json/skills", 1)
	b.reset_cost_per_point = DefReader.integer(d, "reset_cost_per_point", errs, "balance.json/skills", 15)
	return b
