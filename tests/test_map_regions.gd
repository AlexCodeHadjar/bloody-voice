extends TestSuite
## Known points of the city map art must land in the right district.

const SAMPLES := {
	Vector2(615, 585): &"CROWN",
	Vector2(200, 500): &"AVENUES",
	Vector2(880, 220): &"NORDHAL",
	Vector2(540, 260): &"SILVERHILL",
	Vector2(1070, 800): &"EXCHANGE",
	Vector2(175, 820): &"EXCHANGE",
	Vector2(620, 120): &"EXCHANGE",
	Vector2(540, 1010): &"SCARLET",
	Vector2(880, 950): &"DEEPWRIGHT",
	Vector2(1030, 520): &"GREY",
	Vector2(805, 640): &"LUMEN",
	Vector2(780, 430): &"VIGIL",
	Vector2(415, 560): &"MORRELL",
	Vector2(630, 770): &"MARKET",
	Vector2(20, 20): &"",
}


func test_samples() -> void:
	var map := load_content(false).map_regions
	for p: Vector2 in SAMPLES:
		eq(MapRegionRules.district_at(map, p), SAMPLES[p], "point %s" % p)


func test_every_anchor_is_inside_its_region() -> void:
	var map := load_content(false).map_regions
	for r: MapRegionsDef.Region in map.regions:
		eq(MapRegionRules.district_at(map, r.center), r.district, "anchor of %s" % r.id)
