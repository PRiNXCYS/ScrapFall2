## A Skitter's low-poly body, driven by a SkitterBrain.
class_name Skitter
extends Node3D

var brain := SkitterBrain.new()
var _legs: Array[Node3D] = []
var _t := 0.0
var _climbed := false
var _local := Vector3.ZERO


func _ready() -> void:
	scale = Vector3.ONE * randf_range(1.2, 1.6)
	_t = randf() * 10.0
	var bm := SphereMesh.new()
	bm.radius = .9
	bm.height = 1.1
	bm.radial_segments = 8
	bm.rings = 4
	var b := Art.part(self, bm, "rust", Vector3(0, .85, 0))
	b.scale = Vector3(1.0, .8, 1.3)
	Art.box(self, Vector3(1.0, .25, 1.1), "rust_d", Vector3(0, 1.35, -.1))
	Art.box(self, Vector3(.22, .22, .1), "eye", Vector3(-.3, 1.0, 1.15))
	Art.box(self, Vector3(.22, .22, .1), "eye", Vector3(.3, 1.0, 1.15))
	for sd in [-1, 1]:
		for z in [-.55, 0.0, .55]:
			var pivot := Node3D.new()
			pivot.position = Vector3(sd * .8, .9, z)
			add_child(pivot)
			Art.box(pivot, Vector3(1.1, .16, .16), "steel", Vector3(sd * .5, .1, 0), Vector3(0, 0, sd * -.5))
			Art.box(pivot, Vector3(.16, 1.0, .16), "steel", Vector3(sd * 1.0, -.35, 0))
			_legs.append(pivot)
	for leg in _legs:
		Art.merge(leg, false, false)
	Art.merge(self, false)  # body, plate and eyes: three meshes instead of five


## Moves the model to the brain's position; hops onto the truck body when it climbs.
func sync(dt: float, truck: Truck) -> void:
	_t += dt * 14.0
	for i in _legs.size():
		_legs[i].rotation.x = sin(_t + i * 1.7) * 0.6
	if brain.state == SkitterBrain.State.ON_TRUCK:
		if not _climbed:
			_climbed = true
			_local = Vector3(randf_range(-1.0, 1.0), 2.9, randf_range(-3.5, 1.5))
			reparent(truck.body, false)
			scale = Vector3.ONE * 0.8
		position = _local + Vector3(0, absf(sin(_t * 0.5)) * 0.15, 0)
		return
	var old := position
	position = brain.pos
	var dir := position - old
	dir.y = 0
	if dir.length() > 0.01:
		look_at(position + dir.normalized(), Vector3.UP, true)
