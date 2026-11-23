## Auto turret: climbers first, range, ignores dead, fire rate, kills.
extends TestCase

var turret: Turret


func _b(pos: Vector3, state := SkitterBrain.State.RUN) -> SkitterBrain:
	var b := SkitterBrain.new()
	b.pos = pos
	b.state = state
	return b


func cleanup() -> void:
	if is_instance_valid(turret):
		turret.free()


func _turret() -> Turret:
	turret = Turret.new()
	tree.root.add_child(turret)
	return turret


func test_targets_climber_first() -> void:
	var near := _b(Vector3(0, 0, 5))
	var climber := _b(Vector3(0, 0, 12), SkitterBrain.State.ON_TRUCK)
	assert_true(Targeting.pick(Vector3.ZERO, [near, climber]) == climber, "climber wins")


func test_ignores_out_of_range() -> void:
	assert_true(Targeting.pick(Vector3.ZERO, [_b(Vector3(0, 0, 31))]) == null, "31 m is out of 30 m range")


func test_ignores_dead() -> void:
	var d := _b(Vector3(0, 0, 3), SkitterBrain.State.DEAD)
	var live := _b(Vector3(0, 0, 20))
	assert_true(Targeting.pick(Vector3.ZERO, [d, live]) == live, "dead ones skipped")


func test_fire_rate() -> void:
	var t := _turret()
	var b := _b(Vector3(0, 0, 10))
	b.hp = 1000.0
	for i in 120:
		t.tick(1.0 / 60.0, [b])
	assert_true(t.shots == 12 or t.shots == 13, "one shot per 0.16 s, got %d" % t.shots)


func test_kills_after_four_hits() -> void:
	var t := _turret()
	var b := _b(Vector3(0, 0, 10))
	for i in 60:
		t.tick(1.0 / 60.0, [b])
	assert_eq(b.state, SkitterBrain.State.DEAD, "4 hp, 1 damage per shot")
	assert_eq(t.kills, 1, "kill counted")
