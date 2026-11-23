## Endless road: constant chunk count, always covered ahead, props off the road, origin shift.
extends TestCase

var road: Road


func _make() -> Road:
	road = Road.new()
	tree.root.add_child(road)
	road.setup(42)
	return road


func cleanup() -> void:
	if is_instance_valid(road):
		road.free()


func test_chunk_count_stays_constant() -> void:
	_make()
	for z in range(0, 5000, 7):
		road.follow(float(z))
	assert_eq(road.chunk_nodes.size(), RoadPlan.CHUNKS, "chunks recycled, not piled up")


func test_road_covers_ahead() -> void:
	_make()
	var ok := true
	for z in range(0, 3000, 11):
		road.follow(float(z))
		var last: Node3D = road.chunk_nodes[-1]
		if last.position.z + RoadPlan.CHUNK / 2 < z + RoadPlan.CHUNK * 4:
			ok = false
	assert_true(ok, "road always reaches four chunks ahead")


func test_props_never_on_road() -> void:
	var plan := RoadPlan.new()
	var ok := true
	for s in 500:
		for p in plan.prop_layout(s):
			if absf(p["pos"].x) < RoadPlan.ROAD_W / 2 + 4:
				ok = false
	assert_true(ok, "props stay at least 4 m off the road")


func test_same_seed_same_props() -> void:
	var plan := RoadPlan.new()
	assert_eq(str(plan.prop_layout(9)), str(plan.prop_layout(9)), "deterministic")


func test_origin_shift_keeps_relative_positions() -> void:
	var plan := RoadPlan.new()
	assert_true(not plan.should_shift(1999.0), "no shift before 2 km")
	assert_true(plan.should_shift(2001.0), "shift after 2 km")
	_make()
	road.follow(2001.0)
	var before: Array = road.chunk_nodes.map(func(c): return c.position.z)
	road.shift(-2000.0)
	var after: Array = road.chunk_nodes.map(func(c): return c.position.z)
	var ok := true
	for i in before.size():
		if not is_equal_approx(before[i] - 2000.0, after[i]):
			ok = false
	assert_true(ok, "every chunk moved back exactly 2000 m")
