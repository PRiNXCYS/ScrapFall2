## Truck driving rules (no nodes): speed, boost meter, steering inside the road, health.
class_name TruckDrive
extends RefCounted

const BASE_SPEED := 22.0
const BOOST_SPEED := 40.0
const STEER_RATE := 11.0
const BOOST_DRAIN := 0.45
const BOOST_REGEN := 0.18
const MAX_HP := 100.0
const RAM_SPEED := 30.0

var x := 0.0
var z := 0.0
var speed := BASE_SPEED
var boost := 1.0
var hp := MAX_HP
var boosting := false
var parked := false
var steer := 0.0


func step(dt: float, steer_in: float, want_boost: bool) -> void:
	steer = steer_in
	boosting = want_boost and boost > 0.0 and not parked
	boost = clampf(boost + (-BOOST_DRAIN if boosting else BOOST_REGEN) * dt, 0.0, 1.0)
	if boost <= 0.0:
		boosting = false
	if parked:
		speed = 0.0
		return
	var target := BOOST_SPEED if boosting else BASE_SPEED
	speed = lerpf(speed, target, 1.0 - exp(-3.0 * dt))
	z += speed * dt
	x = clampf(x + steer_in * STEER_RATE * dt, -half_width(), half_width())


func ramming() -> bool:
	return boosting and speed > RAM_SPEED


func damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)


func dead() -> bool:
	return hp <= 0.0


func half_width() -> float:
	return RoadPlan.ROAD_W / 2 - 1.6
