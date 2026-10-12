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
var tags: Dictionary[StringName, ContractDefs.TagDef] = {}  ## creature sign tags (GDD 8.2)
var petitions: Array[ContractDefs.PetitionDef] = []
var rumor_data: RumorDefs.Data = RumorDefs.Data.new()  ## witnesses and zone pictures/tags of rumors (GDD 8)
var blueprints: Dictionary[StringName, WorkshopDefs.BlueprintDef] = {}  ## item id -> blueprint (GDD 6.2)
var blueprint_order: Array[StringName] = []
var factions: Array[StandingDefs.FactionDef] = []  ## factions of the slice (GDD 12)
var webs: Dictionary[StringName, SkillDefs.WebDef] = {}  ## skill webs by id: mechanic, later monster (GDD 4.4)


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


func blueprint(item: StringName) -> WorkshopDefs.BlueprintDef:
	return blueprints.get(item) as WorkshopDefs.BlueprintDef


## Every trophy id a creature part can give.
func trophy_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for m: MonsterDef in monsters.values():
		for p: MonsterDef.PartDef in m.parts:
			if p.trophy != &"" and not out.has(p.trophy):
				out.append(p.trophy)
	return out


func tag(id: StringName) -> ContractDefs.TagDef:
	return tags.get(id) as ContractDefs.TagDef


func faction(id: StringName) -> StandingDefs.FactionDef:
	for f: StandingDefs.FactionDef in factions:
		if f.id == id:
			return f
	return null


func petition(id: StringName) -> ContractDefs.PetitionDef:
	for p: ContractDefs.PetitionDef in petitions:
		if p.id == id:
			return p
	return null
