## Truck driving rules: boost meter, road clamp, parking, ramming, damage.
extends TestCase


func _run(d: TruckDrive, secs: float, steer := 0.0, boost := false) -> void:
	for i in int(secs * 60):
		d.step(1.0 / 60.0, steer, boost)


func test_boost_drains_and_regens() -> void:
	var d := TruckDrive.new()
	_run(d, 1.0, 0.0, true)
	assert_true(absf(d.boost - 0.55) < 0.011, "1 s of boost drains 0.45, got %s" % d.boost)
	_run(d, 1.0)
	assert_true(absf(d.boost - 0.73) < 0.011, "1 s rest regens 0.18, got %s" % d.boost)


func test_cannot_boost_when_empty() -> void:
	var d := TruckDrive.new()
	_run(d, 3.0, 0.0, true)
	assert_true(not d.boosting, "empty meter stops the boost")


func test_steer_clamped_to_road() -> void:
	var d := TruckDrive.new()
	_run(d, 10.0, 1.0)
	assert_true(is_equal_approx(d.x, d.half_width()), "stops at the road edge")
	_run(d, 10.0, -1.0)
	assert_true(is_equal_approx(d.x, -d.half_width()), "and the other edge")


func test_parked_truck_does_not_move() -> void:
	var d := TruckDrive.new()
	d.parked = true
	_run(d, 2.0, 1.0, true)
	assert_eq(d.z, 0.0, "no forward motion")
	assert_eq(d.x, 0.0, "no steering")


func test_ramming_needs_speed() -> void:
	var d := TruckDrive.new()
	_run(d, 0.5)
	assert_true(not d.ramming(), "cruising is not ramming")
	_run(d, 1.0, 0.0, true)
	assert_true(d.ramming(), "boosting above 30 is ramming (speed %s)" % d.speed)


func test_damage_and_death() -> void:
	var d := TruckDrive.new()
	d.damage(40.0)
	assert_true(not d.dead(), "alive at 60")
	d.damage(60.0)
	assert_true(d.dead(), "dead at 0")
