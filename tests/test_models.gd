## Detailed truck and guns stay cheap for phones, and the first-person gun kicks and settles.
extends TestCase

var nodes: Array = []


func cleanup() -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.free()


func _meshes(n: Node) -> int:
	return n.find_children("*", "MeshInstance3D", true, false).size()


func test_fp_gun_is_detailed_but_cheap() -> void:
	var p := PlayerFP.new()
	tree.root.add_child(p)
	nodes.append(p)
	assert_true(p.gun_parts >= 15, "gun and hands built from 15+ parts, got %d" % p.gun_parts)
	assert_true(_meshes(p) <= 8, "merged to at most 8 meshes, got %d" % _meshes(p))


func test_fp_gun_recoils_and_settles() -> void:
	var p := PlayerFP.new()
	tree.root.add_child(p)
	nodes.append(p)
	var rest: Vector3 = p.gun_rest
	p.fire([])
	p.tick(1.0 / 60.0)
	assert_true(p.gun_node().position.z > rest.z + 0.02, "kicks back toward the camera")
	for i in 60:
		p.tick(1.0 / 60.0)
	assert_true(p.gun_node().position.distance_to(rest) < 0.01, "settles back")


func test_roof_gun_is_cheap() -> void:
	var g := Turret.new()
	tree.root.add_child(g)
	nodes.append(g)
	assert_true(g.detail_parts >= 12, "M2 roof gun built from 12+ parts, got %d" % g.detail_parts)
	assert_true(_meshes(g) <= 8, "merged to at most 8 meshes, got %d" % _meshes(g))
