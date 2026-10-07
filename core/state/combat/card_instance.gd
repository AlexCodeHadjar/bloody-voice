class_name CardInstance
extends RefCounted
## One physical card in a fight. uid tells apart two copies of the same CardDef.

var uid: int
var def: CardDef


static func create(uid_value: int, card_def: CardDef) -> CardInstance:
	var c := CardInstance.new()
	c.uid = uid_value
	c.def = card_def
	return c
