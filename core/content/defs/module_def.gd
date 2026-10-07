class_name ModuleDef
extends RefCounted
## A weapon module (data/gear/modules.json): shape, cell type, cards, passive mods, links with neighbours.

class LinkDef:
	var with_module: StringName  ## when this module touches that one...
	var replace: Dictionary[StringName, StringName] = {}  ## ...these cards of the deck are swapped


var id: StringName
var name: String
var section: StringName
var shape: StringName
var cell: StringName
var cards: Array[StringName] = []
var capture_cards: Array[StringName] = []  ## added only on capture contracts
var mods: Dictionary[StringName, int] = {}
var links: Array[LinkDef] = []
var effect: String
var look: String


## Art fitted to the module's cell shape (tools/import_art.py), drawn unrotated.
func art_path() -> String:
	return "res://art/gear/modules/%s__module__normal.webp" % String(id).to_upper()


static func from_dict(d: Dictionary, errs: ErrorLog) -> ModuleDef:
	var m := ModuleDef.new()
	m.id = DefReader.id(d, "id", errs, "modules.json")
	var w := "modules.json/%s" % m.id
	m.name = DefReader.string(d, "name", errs, w)
	m.section = DefReader.id(d, "section", errs, w)
	m.shape = DefReader.id(d, "shape", errs, w)
	m.cell = DefReader.id(d, "cell", errs, w)
	m.cards = DefReader.ids(d, "cards", errs, w)
	m.capture_cards = DefReader.ids(d, "capture_cards", errs, w)
	m.mods = GearMods.read(d, errs, w)
	m.effect = DefReader.string(d, "effect", errs, w)
	m.look = DefReader.string(d, "look", errs, w, false)
	for lv: Variant in DefReader.array(d, "links", errs, w, false):
		var ld: Dictionary = lv
		var link := LinkDef.new()
		link.with_module = DefReader.id(ld, "with", errs, w + "/links")
		var rep := DefReader.dict(ld, "replace", errs, w + "/links")
		for k: Variant in rep:
			link.replace[StringName(str(k))] = StringName(str(rep[k]))
		m.links.append(link)
	return m
