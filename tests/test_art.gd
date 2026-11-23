## Low-poly art kit: flat faces, a complete shared palette.
extends TestCase


func test_flat_mesh_has_face_normals() -> void:
	var s := SphereMesh.new()
	s.radial_segments = 6
	s.rings = 3
	var m := Art.flat(s)
	var n: PackedVector3Array = m.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	assert_true(n.size() > 0 and n.size() % 3 == 0, "deindexed triangles")
	var ok := true
	for i in range(0, n.size(), 3):
		if not (n[i].is_equal_approx(n[i + 1]) and n[i].is_equal_approx(n[i + 2])):
			ok = false
	assert_true(ok, "each triangle has one normal")


func test_palette_complete() -> void:
	for k in ["sand", "sand_d", "road", "line", "rust", "rust_d", "steel", "tire", "cactus", "rock", "cyan", "eye", "tracer", "glass"]:
		assert_true(Art.mat(k) is StandardMaterial3D, "material " + k)
	assert_true(Art.mat("cyan").emission_enabled, "core glows")


func test_materials_are_shared() -> void:
	assert_true(Art.mat("rust") == Art.mat("rust"), "one instance per colour")
