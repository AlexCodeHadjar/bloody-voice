class_name LifeContext
extends RefCounted
## What every resident of the district map shares: the map, the life data, the random stream and the hero to step aside for.

var map: DistrictMapDef
var life: DistrictLifeDef
var rng: RandomNumberGenerator
var hero: Node2D = null
var node_ids: Array[StringName] = []


func texture(sheet: StringName, slot: int) -> Texture2D:
	return UiKit.texture(DistrictLifeDef.figure_path(sheet, slot))


## Random reachable node: from `list`, or anywhere on the street graph when it is empty.
func random_node(list: Array[StringName]) -> StringName:
	var from: Array[StringName] = list if not list.is_empty() else node_ids
	return from[rng.randi_range(0, from.size() - 1)]
