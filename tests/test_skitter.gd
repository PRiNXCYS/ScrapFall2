## Skitters: chase, climb, drain, get rammed, despawn; no tunnelling on big frames; spawner ramps up.
extends TestCase


func _truck() -> TruckDrive:
	var t := TruckDrive.new()
	return t


func _brain(pos: Vector3) -> SkitterBrain:
	var b := SkitterBrain.new()
	b.pos = pos
	b.spd = 18.0
	return b


func test_skitter_reaches_and_climbs() -> void:
	var t := _truck()
	var b := _brain(Vector3(10, 0, 20))
	for i in 300:
		b.step(1.0 / 60.0, t)
	assert_eq(b.state, SkitterBrain.State.ON_TRUCK, "climbed on")


func test_climber_drains_truck() -> void:
	var t := _truck()
	var b := _brain(Vector3.ZERO)
	b.state = SkitterBrain.State.ON_TRUCK
	for i in 60:
		b.step(1.0 / 60.0, t)
	assert_true(absf(t.hp - 97.5) < 0.05, "2.5 hp per second, hp %s" % t.hp)


func test_ram_kills_in_front() -> void:
	var t := _truck()
	t.boosting = true
	t.speed = 35.0
	var b := _brain(Vector3(0.5, 0, 5.0))
	b.step(1.0 / 60.0, t)
	assert_eq(b.state, SkitterBrain.State.DEAD, "rammed")


func test_falls_behind_and_despawns() -> void:
	var t := _truck()
	var b := _brain(Vector3(0, 0, -41.0))
	b.step(1.0 / 60.0, t)
	assert_eq(b.state, SkitterBrain.State.GONE, "left behind")


func test_big_delta_does_not_tunnel() -> void:
	var t := _truck()
	t.speed = 40.0
	var b := _brain(Vector3(0, 0, 9.0))
	b.step(0.25, t)
	assert_true(b.state == SkitterBrain.State.ON_TRUCK or b.state == SkitterBrain.State.DEAD, "caught, state %s" % b.state)


func test_hit_kills_after_hp() -> void:
	var b := _brain(Vector3.ZERO)
	for i in 3:
		assert_true(not b.hit(1.0), "still alive after %d" % (i + 1))
	assert_true(b.hit(1.0), "fourth hit kills")
	assert_eq(b.state, SkitterBrain.State.DEAD, "dead")


func test_spawner_gets_harder() -> void:
	var early := Spawner.new()
	var late := Spawner.new()
	var a := 0
	var c := 0
	for i in 3600:
		a += early.due(1.0 / 60.0, 0.0)
		c += late.due(1.0 / 60.0, 3000.0)
	assert_true(c > a, "more at 3 km (%d) than at 0 km (%d)" % [c, a])


func test_swarm_every_900m() -> void:
	var s := Spawner.new()
	var swarms := 0
	for d in range(0, 3000, 5):
		s.due(0.0, float(d))
		if s.swarm_now:
			swarms += 1
	assert_eq(swarms, 3, "swarms at 600, 1500, 2400")
