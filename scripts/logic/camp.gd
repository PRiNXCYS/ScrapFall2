## The night camp around the parked truck: a 2 m grid, guns and walls bought with scrap, waves.
class_name Camp
extends RefCounted

const CELL := 2.0
const RADIUS := 14.0
const COST := {"gun": 10, "wall": 3}
const HP := {"gun": 20.0, "wall": 30.0}
const SLOTS := 4
const BUILD_SECONDS := 15.0

var scrap := 0
var origin := Vector3.ZERO  # where the truck parked
var structures := {}  # Vector2i -> {"kind": String, "hp": float}
var slots := {}  # slot index -> kind


func on_phase(cycle: DayCycle, drive: TruckDrive) -> void:
	if cycle.entered_night:
		drive.parked = true
		origin = Vector3(drive.x, 0, drive.z)
		structures.clear()
	elif cycle.entered_day:
		drive.parked = false


func cell_of(world: Vector3) -> Vector2i:
	var p := world - origin
	return Vector2i(floori(p.x / CELL), floori(p.z / CELL))


func cell_center(c: Vector2i) -> Vector3:
	return origin + Vector3(c.x * CELL + CELL / 2, 0, c.y * CELL + CELL / 2)


func on_truck(c: Vector2i) -> bool:
	return c.x >= -1 and c.x <= 0 and c.y >= -3 and c.y <= 2


func can_place(c: Vector2i) -> bool:
	return not on_truck(c) and not structures.has(c) and (cell_center(c) - origin).length() <= RADIUS


func place(kind: String, c: Vector2i) -> bool:
	if not COST.has(kind) or not can_place(c) or scrap < COST[kind]:
		return false
	scrap -= COST[kind]
	structures[c] = {"kind": kind, "hp": HP[kind]}
	return true


func slot_place(slot: int, kind := "gun") -> bool:
	if slot < 0 or slot >= SLOTS or slots.has(slot) or scrap < COST[kind]:
		return false
	scrap -= COST[kind]
	slots[slot] = kind
	return true


## Is this world point inside a wall or tower? (SkitterBrain.step_camp uses this.)
func blocked(world: Vector3) -> bool:
	return structures.has(cell_of(world))


## Damage whatever stands at this point; returns true when it breaks.
func chew(world: Vector3, dmg: float) -> bool:
	var c := cell_of(world)
	if not structures.has(c):
		return false
	structures[c]["hp"] -= dmg
	if structures[c]["hp"] <= 0.0:
		structures.erase(c)
		return true
	return false


## Spawn points for this night: 8 + 4 per night, from 2 sides growing to 4, 40 m out.
func wave(night_index: int) -> Array[Vector3]:
	var sides := [Vector3(0, 0, 40), Vector3(40, 0, 0), Vector3(0, 0, -40), Vector3(-40, 0, 0)]
	var n_sides := 2 + mini(night_index, 2)
	var count := 8 + 4 * night_index
	var out: Array[Vector3] = []
	for i in count:
		var s: Vector3 = sides[i % n_sides]
		var spread := Vector3(s.z, 0, s.x).normalized() * (float(i / n_sides % 5) - 2.0) * 4.0
		out.append(origin + s + spread)
	return out
