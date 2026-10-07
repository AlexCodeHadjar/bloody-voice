class_name ContentData
extends RefCounted
## All loaded game content. Read-only after loading; rules receive it as a parameter.

var balance: BalanceDef = BalanceDef.new()
var districts: Dictionary[StringName, DistrictDef] = {}
var district_order: Array[StringName] = []
var district_states: Dictionary[StringName, DistrictStateDef] = {}
var map_regions: MapRegionsDef = MapRegionsDef.new()


func district(id: StringName) -> DistrictDef:
	return districts.get(id) as DistrictDef
