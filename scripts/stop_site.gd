## A roadside scrap yard you explore on foot: walls, wrecks, 3 loot crates (5 scrap each), Skitter nests.
class_name StopSite
extends Node3D

const CRATE_SCRAP := 5
const LOOT_DIST := 2.5

var _crates := {}  # Vector3 (local) -> MeshInstance3D
var skitter_spots: Array[Vector3] = []


func _ready() -> void:
	Art.box(self, Vector3(30, 0.02, 30), "sand_d", Vector3(0, 0.0, 0))
	for w in [[Vector3(0, 1.5, 15), Vector3(30, 3, 0.6)], [Vector3(0, 1.5, -15), Vector3(18, 3, 0.6)],
			[Vector3(15, 1.5, 0), Vector3(0.6, 3, 30)], [Vector3(-15, 1.5, 4), Vector3(0.6, 3, 22)]]:
		_wall(w[0], w[1])
	_wall(Vector3(-4, 1.2, 3), Vector3(6, 2.4, 0.6))
	_wall(Vector3(5, 1.2, -4), Vector3(0.6, 2.4, 7))
	for p in [Vector3(-9, 0, 9), Vector3(9, 0, 8), Vector3(-8, 0, -8)]:
		var w := Node3D.new()
		w.position = p
		w.rotation.y = p.x * 0.3
		add_child(w)
		Art.box(w, Vector3(2.2, .9, 4.4), "rust_d", Vector3(0, .5, 0), Vector3(0, 0, .12))
		Art.box(w, Vector3(1.9, .7, 2.0), "rust", Vector3(0, 1.2, -.3), Vector3(0, 0, .12))
	for p in [Vector3(-11, 0, 12), Vector3(11, 0, -11), Vector3(2, 0, 10)]:
		_crates[p] = Art.box(self, Vector3(1.2, 1.0, 1.2), "rust", p + Vector3(0, .5, 0))
		Art.box(_crates[p], Vector3(1.25, .15, 1.25), "line", Vector3(0, .3, 0))
	skitter_spots = [Vector3(-10, 0, 5), Vector3(10, 0, 4), Vector3(0, 0, 12), Vector3(-6, 0, -10), Vector3(8, 0, -6)]


func _wall(pos: Vector3, size: Vector3) -> void:
	Art.box(self, size, "wall", pos)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	body.position = pos
	add_child(body)


func crate_positions() -> Array:
	return _crates.keys().map(func(p): return to_global(p))


func loot_left() -> int:
	return _crates.size()


## Opens the nearest crate within reach of a world position; returns the scrap gained.
func loot_near(world: Vector3) -> int:
	for p in _crates.keys():
		var g := to_global(p)
		if Vector2(g.x - world.x, g.z - world.z).length() <= LOOT_DIST:
			_crates[p].queue_free()
			_crates.erase(p)
			return CRATE_SCRAP
	return 0
