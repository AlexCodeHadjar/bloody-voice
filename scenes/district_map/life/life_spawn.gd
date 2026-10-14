class_name LifeSpawn
extends RefCounted
## Builds the residents, scenes and effects of a district map from its life data (all random choices from the context).


static func build(layer: Node2D, ctx: LifeContext) -> Array[Resident]:
	var out: Array[Resident] = []
	for r: DistrictLifeDef.ResidentDef in ctx.life.residents + walkers(ctx):
		var node := Resident.new()
		node.setup(r, ctx)
		layer.add_child(node)
		out.append(node)
	for p: DistrictLifeDef.PropDef in ctx.life.scenes:
		_props(layer, ctx, p, ctx.life.scene_scale)
	for p: DistrictLifeDef.PropDef in ctx.life.fx:
		_props(layer, ctx, p, 1.0)
	return out


## Passers-by of the current period: random kinds by weight, random person of the sheet (slots 1-2, 3-4, 5-6, 7-8).
static func walkers(ctx: LifeContext) -> Array[DistrictLifeDef.ResidentDef]:
	var out: Array[DistrictLifeDef.ResidentDef] = []
	var kinds := ctx.life.kinds_for(ctx.life.period)
	var weights: Array[float] = []
	var total := 0.0
	for k: DistrictLifeDef.WalkerKind in kinds:
		weights.append(k.weight)
		total += k.weight
	if kinds.is_empty():
		return out
	for i: int in ctx.life.walker_count:
		var kind := kinds[LifeFacing.weighted_index(weights, ctx.rng.randf() * total)]
		var r := DistrictLifeDef.ResidentDef.new()
		r.group = &"walkers"
		r.id = StringName("walker_%d" % i)
		r.art = kind.set_id
		r.slot = ctx.rng.randi_range(0, 3) * 2 + 1
		r.mode = &"wander"
		r.speed = kind.speed
		r.scale = kind.scale
		r.chat = true
		out.append(r)
	return out


static func _props(layer: Node2D, ctx: LifeContext, p: DistrictLifeDef.PropDef, default_scale: float) -> void:
	for pt: Vector2 in p.points:
		var prop := LifeProp.new()
		prop.setup(p, pt, p.scale if p.scale > 0.0 else default_scale, ctx.rng)
		layer.add_child(prop)
