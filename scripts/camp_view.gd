## Shows the night camp: walls and gun towers on the grid, a green/red ghost under your finger.
class_name CampView
extends Node3D

var camp: Camp
var selected := "gun"
var _nodes := {}  # Vector2i -> Node3D
var _guns: Array[Turret] = []
var _ghost: MeshInstance3D


func setup(c: Camp) -> void:
	camp = c
	_ghost = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(Camp.CELL * 0.95, 0.2, Camp.CELL * 0.95)
	_ghost.mesh = b
	_ghost.visible = false
	add_child(_ghost)


## Rebuild visuals to match camp.structures (cheap: only adds/removes what changed).
func refresh() -> void:
	for c in _nodes.keys():
		if not camp.structures.has(c):
			_nodes[c].queue_free()
			_nodes.erase(c)
	_guns = _guns.filter(func(g): return is_instance_valid(g) and not g.is_queued_for_deletion())
	for c in camp.structures:
		if _nodes.has(c):
			continue
		var n := Node3D.new()
		add_child(n)
		n.global_position = camp.cell_center(c)
		if camp.structures[c]["kind"] == "wall":
			Art.box(n, Vector3(Camp.CELL, 1.6, Camp.CELL), "wall", Vector3(0, .8, 0))
			Art.box(n, Vector3(Camp.CELL * 0.9, .25, Camp.CELL * 0.9), "rust_d", Vector3(0, 1.7, 0))
		else:
			Art.box(n, Vector3(1.6, 1.0, 1.6), "steel", Vector3(0, .5, 0))
			var g := Turret.new()
			g.configure(0.3, 1.5, 22.0)
			g.position = Vector3(0, 1.0, 0)
			n.add_child(g)
			_guns.append(g)
		_nodes[c] = n


func clear() -> void:
	for n in _nodes.values():
		n.queue_free()
	_nodes.clear()
	_guns.clear()
	_ghost.visible = false


func tick(dt: float, brains: Array) -> int:
	var kills := 0
	for g in _guns:
		if is_instance_valid(g):
			var before := g.kills
			g.tick(dt, brains)
			kills += g.kills - before
	return kills


func hover(world: Vector3) -> void:
	var c := camp.cell_of(world)
	_ghost.visible = true
	_ghost.global_position = camp.cell_center(c) + Vector3(0, 0.1, 0)
	var ok := camp.can_place(c) and camp.scrap >= Camp.COST[selected]
	_ghost.material_override = Art.mat("ghost_ok" if ok else "ghost_bad")


func try_place(world: Vector3) -> bool:
	var ok := camp.place(selected, camp.cell_of(world))
	if ok:
		refresh()
	return ok
