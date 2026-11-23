## One Skitter's rules (no nodes): chase the truck, climb on, drain it, get rammed or shot.
class_name SkitterBrain
extends RefCounted

enum State { RUN, ON_TRUCK, DEAD, GONE }

const HP := 4.0
const CLIMB_DIST := 3.2
const CLIMB_DPS := 2.5
const MAX_STEP := 0.05
const RAM_HALF := 2.2
const BEHIND := 40.0

var pos := Vector3.ZERO
var hp := HP
var state := State.RUN
var spd := 18.0
var rammed := false
## Night camp: what it is chewing on (Vector3.INF when nothing) and whether it reached its target.
var chewing := Vector3.INF
var at_target := false


## Driving phase. Big frames are cut into steps of at most MAX_STEP so nothing tunnels past the truck.
func step(dt: float, truck: TruckDrive) -> void:
	var left := dt
	while left > 0.0 and state == State.RUN:
		var h := minf(left, MAX_STEP)
		left -= h
		_run_step(h, truck)
	if state == State.ON_TRUCK:
		truck.damage(CLIMB_DPS * dt)


func _run_step(h: float, truck: TruckDrive) -> void:
	var tp := Vector3(truck.x, 0, truck.z)
	if pos.z < truck.z - BEHIND:
		state = State.GONE
		return
	var target := tp + Vector3(0, 0, 3.0)
	if _try_contact(target, truck):
		return
	var to := target - pos
	to.y = 0
	pos += to.normalized() * minf(to.length(), (spd + truck.speed * 0.75) * h)
	_try_contact(target, truck)


func _try_contact(target: Vector3, truck: TruckDrive) -> bool:
	if pos.distance_to(target) >= CLIMB_DIST:
		return false
	if truck.ramming() and pos.z > truck.z and absf(pos.x - truck.x) < RAM_HALF:
		state = State.DEAD
		rammed = true
	else:
		state = State.ON_TRUCK
	return true


## Night camp phase: walk to target; stop and chew on anything `blocked` says is in the way.
func step_camp(dt: float, target: Vector3, blocked: Callable) -> void:
	chewing = Vector3.INF
	at_target = false
	if state != State.RUN:
		return
	var left := dt
	while left > 0.0:
		var h := minf(left, MAX_STEP)
		left -= h
		var to := target - pos
		to.y = 0
		if to.length() < CLIMB_DIST:
			at_target = true
			return
		var nxt := pos + to.normalized() * minf(to.length(), spd * h)
		if blocked.is_valid() and blocked.call(nxt):
			chewing = nxt
			return
		pos = nxt


## Returns true when this hit kills it.
func hit(dmg: float) -> bool:
	if state == State.DEAD or state == State.GONE:
		return false
	hp -= dmg
	if hp <= 0.0:
		state = State.DEAD
		return true
	return false
