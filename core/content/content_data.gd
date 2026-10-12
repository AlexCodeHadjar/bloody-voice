class_name ContentData
extends RefCounted
## All loaded game content. Read-only after loading; rules receive it as a parameter.

var balance: BalanceDef = BalanceDef.new()
var districts: Dictionary[StringName, DistrictDef] = {}
var district_order: Array[StringName] = []
var district_states: Dictionary[StringName, DistrictStateDef] = {}
var map_regions: MapRegionsDef = MapRegionsDef.new()
var district_maps: Dictionary[StringName, DistrictMapDef] = {}
var district_life: Dictionary[StringName, DistrictLifeDef] = {}
var cards: Dictionary[StringName, CardDef] = {}
var monsters: Dictionary[StringName, MonsterDef] = {}
var monster_order: Array[StringName] = []
var weapons: Dictionary[StringName, WeaponDef] = {}
var modules: Dictionary[StringName, ModuleDef] = {}
var shapes: Dictionary[StringName, GearDefs.ShapeDef] = {}
var armor: Array[GearDefs.ArmorDef] = []
var mechanisms: Dictionary[StringName, GearDefs.MechanismDef] = {}
var audio: AudioDef = AudioDef.new()
var tutorial: Dictionary[StringName, TutorialDef] = {}


func district(id: StringName) -> DistrictDef:
	return districts.get(id) as DistrictDef


func district_map(id: StringName) -> DistrictMapDef:
	return district_maps.get(id) as DistrictMapDef


func life(id: StringName) -> DistrictLifeDef:
	return district_life.get(id) as DistrictLifeDef


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
