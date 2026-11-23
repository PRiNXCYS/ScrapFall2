## When and where Skitters appear while driving; harder the farther you get, with swarms.
class_name Spawner
extends RefCounted

const SWARM_FIRST := 600.0
const SWARM_EVERY := 900.0
const SWARM_SIZE := 8

var swarm_now := false
var _timer := 1.5
var _next_swarm := SWARM_FIRST


func interval(dist: float) -> float:
	return maxf(0.6, 2.4 - dist / 2500.0)


func batch(dist: float) -> int:
	return mini(1 + int(dist / 900.0), 6)


## How many to spawn this frame.
func due(dt: float, dist: float) -> int:
	var n := 0
	swarm_now = false
	_timer -= dt
	if _timer <= 0.0:
		n += batch(dist)
		_timer = interval(dist)
	if dist >= _next_swarm:
		_next_swarm += SWARM_EVERY
		swarm_now = true
		n += SWARM_SIZE
	return n


func spawn_pos(rng: RandomNumberGenerator, truck_z: float) -> Vector3:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	return Vector3(side * rng.randf_range(6.0, 38.0), 0, truck_z + rng.randf_range(35.0, 110.0))
