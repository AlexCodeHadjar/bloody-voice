class_name ContentData
extends RefCounted
## All loaded game content. Read-only after loading; rules receive it as a parameter.

var balance: BalanceDef = BalanceDef.new()
var districts: Dictionary[StringName, DistrictDef] = {}
var district_order: Array[StringName] = []
var district_states: Dictionary[StringName, DistrictStateDef] = {}
var map_regions: MapRegionsDef = MapRegionsDef.new()
var cards: Dictionary[StringName, CardDef] = {}
var monsters: Dictionary[StringName, MonsterDef] = {}
var monster_order: Array[StringName] = []
var weapons: Dictionary[StringName, WeaponDef] = {}
var modules: Dictionary[StringName, ModuleDef] = {}
var shapes: Dictionary[StringName, GearDefs.ShapeDef] = {}
var armor: Array[GearDefs.ArmorDef] = []
var mechanisms: Dictionary[StringName, GearDefs.MechanismDef] = {}


func district(id: StringName) -> DistrictDef:
	return districts.get(id) as DistrictDef


func card(id: StringName) -> CardDef:
	return cards.get(id) as CardDef


func monster(id: StringName) -> MonsterDef:
	return monsters.get(id) as MonsterDef


func weapon(id: StringName) -> WeaponDef:
	return weapons.get(id) as WeaponDef


func module(id: StringName) -> ModuleDef:
	return modules.get(id) as ModuleDef


func mechanism(id: StringName) -> GearDefs.MechanismDef:
	return mechanisms.get(id) as GearDefs.MechanismDef
