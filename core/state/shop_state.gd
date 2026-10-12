class_name ShopState
extends RefCounted
## The Rag-and-Bone shop's table this week (GDD 11.1). Saved. Prices are fixed when the stock is made.
## ShopRules changes it; screens only read it.


class Item:
	var uid: int
	var kind: StringName  ## module / blueprint / consumable / resource (ShopDefs.KINDS)
	var id: StringName  ## module, blueprint item, card or resource id
	var amount: int = 1  ## resource lots: how many
	var price: int
	var sold: bool = false

	func to_dict() -> Dictionary:
		return {"uid": uid, "kind": kind, "id": id, "amount": amount, "price": price, "sold": sold}

	static func from_dict(d: Dictionary) -> Item:
		var x := Item.new()
		x.uid = int(d.get("uid", 0))
		x.kind = StringName(str(d.get("kind", "")))
		x.id = StringName(str(d.get("id", "")))
		x.amount = int(d.get("amount", 1))
		x.price = int(d.get("price", 0))
		x.sold = bool(d.get("sold", false))
		return x


var items: Array[Item] = []
var week: int = 0  ## the week the table was last stocked; 0 = never
var next_uid: int = 1


func find(uid: int) -> Item:
	for x: Item in items:
		if x.uid == uid:
			return x
	return null


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for x: Item in items:
		list.append(x.to_dict())
	return {"items": list, "week": week, "next_uid": next_uid}


static func from_dict(d: Dictionary) -> ShopState:
	var s := ShopState.new()
	for v: Variant in d.get("items", []) as Array:
		s.items.append(Item.from_dict(v as Dictionary))
	s.week = int(d.get("week", 0))
	s.next_uid = int(d.get("next_uid", 1))
	return s
