## The endless desert road: a ring of chunks recycled ahead of the truck, with low-poly props.
class_name Road
extends Node3D

var plan := RoadPlan.new()
var chunk_nodes: Array[Node3D] = []
var _seed := 0
var _count := 0


func setup(seed: int) -> void:
	_seed = seed
	for i in RoadPlan.CHUNKS:
		_add_chunk((i - 1) * RoadPlan.CHUNK)


func follow(truck_z: float) -> void:
	while chunk_nodes[0].position.z + RoadPlan.CHUNK / 2 < truck_z - RoadPlan.CHUNK * 1.5 \
			or plan.chunks_needed(truck_z, chunk_nodes[-1].position.z) > 0:
		var first: Node3D = chunk_nodes.pop_front()
		first.free()
		_add_chunk(chunk_nodes[-1].position.z + RoadPlan.CHUNK)


func shift(dz: float) -> void:
	for c in chunk_nodes:
		c.position.z += dz


func _add_chunk(z: float) -> void:
	var c := Node3D.new()
	c.position.z = z
	add_child(c)
	Art.box(c, Vector3(220, 0.02, RoadPlan.CHUNK), "sand", Vector3(0, -0.01, 0))
	Art.box(c, Vector3(RoadPlan.ROAD_W, 0.02, RoadPlan.CHUNK), "road", Vector3(0, 0.01, 0))
	for i in 6:
		Art.box(c, Vector3(0.35, 0.03, 4.0), "line", Vector3(0, 0.03, -RoadPlan.CHUNK / 2 + 5 + i * 10))
	for side in [-1, 1]:
		for i in 8:
			Art.part(c, Art.rock_mesh(0.3 + 0.03 * ((i * 7 + _count) % 6)), "sand_d", Vector3(side * (RoadPlan.ROAD_W / 2 + 0.6), 0.1, -RoadPlan.CHUNK / 2 + i * 7.5))
	for p in plan.prop_layout(_seed * 1000 + _count):
		_prop(c, p)
	_count += 1
	chunk_nodes.append(c)


func _prop(c: Node3D, p: Dictionary) -> void:
	var at: Vector3 = p["pos"]
	match p["kind"]:
		"rock":
			Art.part(c, Art.rock_mesh(p["size"]), "rock", at + Vector3(0, 0.3, 0), Vector3(0, p["rot"], 0))
		"cactus":
			var h: float = 2.0 + p["size"] * 0.6
			Art.box(c, Vector3(.6, h, .6), "cactus", at + Vector3(0, h / 2, 0))
			Art.box(c, Vector3(1.0, .45, .45), "cactus", at + Vector3(.6, h * .55, 0))
			Art.box(c, Vector3(.45, 1.1, .45), "cactus", at + Vector3(1.0, h * .55 + .5, 0))
		"wreck":
			var w := Node3D.new()
			w.position = at
			w.rotation.y = p["rot"]
			c.add_child(w)
			Art.box(w, Vector3(2.2, .9, 4.4), "rust_d", Vector3(0, .5, 0), Vector3(0, 0, .12))
			Art.box(w, Vector3(1.9, .7, 2.0), "rust", Vector3(0, 1.2, -.3), Vector3(0, 0, .12))
		_:
			for j in 5:
				Art.box(c, Vector3(0.3 + 0.15 * j, .2, 0.5), ["steel", "rust_d", "rust"][j % 3], at + Vector3(j * 0.7 - 1.4, .1, (j % 2) * 0.8), Vector3(0, p["rot"] + j, 0))
