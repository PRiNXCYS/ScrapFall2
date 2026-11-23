## Low-poly art kit: a shared flat-colour palette and helpers that build faceted meshes in code.
class_name Art
extends RefCounted

const PALETTE := {
	"sand": [Color(0.72, 0.46, 0.26), 0.85, 0.0],
	"sand_d": [Color(0.55, 0.36, 0.2), 0.85, 0.0],
	"road": [Color(0.2, 0.17, 0.16), 0.85, 0.0],
	"line": [Color(0.95, 0.85, 0.55), 0.85, 0.0],
	"rust": [Color(0.8, 0.26, 0.07), 0.85, 0.0],
	"rust_d": [Color(0.5, 0.18, 0.07), 0.85, 0.0],
	"steel": [Color(0.28, 0.3, 0.34), 0.55, 0.0],
	"tire": [Color(0.1, 0.1, 0.11), 0.95, 0.0],
	"cactus": [Color(0.36, 0.62, 0.3), 0.85, 0.0],
	"rock": [Color(0.5, 0.34, 0.22), 0.85, 0.0],
	"cyan": [Color(0.2, 0.95, 1.0), 0.3, 1.6],
	"eye": [Color(1.0, 0.18, 0.05), 0.3, 4.0],
	"tracer": [Color(1.0, 0.85, 0.35), 0.3, 6.0],
	"glass": [Color(0.45, 0.75, 0.85), 0.2, 0.0],
	"wall": [Color(0.42, 0.36, 0.3), 0.9, 0.0],
	"ghost_ok": [Color(0.3, 1.0, 0.4), 0.5, 1.0],
	"ghost_bad": [Color(1.0, 0.25, 0.2), 0.5, 1.0],
}

static var _cache := {}


## One shared material per palette key (keeps draw calls and memory low on phones).
static func mat(name: String) -> StandardMaterial3D:
	if _cache.has(name):
		return _cache[name]
	var p: Array = PALETTE[name]
	var m := StandardMaterial3D.new()
	m.albedo_color = p[0]
	m.roughness = p[1]
	if p[2] > 0.0:
		m.emission_enabled = true
		m.emission = p[0]
		m.emission_energy_multiplier = p[2]
	_cache[name] = m
	return m


## Rebuilds a primitive with one normal per triangle: the faceted low-poly look.
static func flat(mesh: Mesh) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.deindex()
	var arrays := st.commit_to_arrays()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n := PackedVector3Array()
	n.resize(v.size())
	for i in range(0, v.size() - 2, 3):  # Godot winds triangles clockwise
		var f := (v[i + 2] - v[i]).cross(v[i + 1] - v[i]).normalized()
		n[i] = f
		n[i + 1] = f
		n[i + 2] = f
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TANGENT] = null
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


static func part(parent: Node3D, mesh: Mesh, mat_name: String, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = flat(mesh)
	mi.material_override = mat(mat_name)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


## Boxes are already flat-faced, so they skip the rebuild.
static func box(parent: Node3D, size: Vector3, mat_name: String, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.material_override = mat(mat_name)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func rock_mesh(r: float) -> Mesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 1.3
	s.radial_segments = 7
	s.rings = 3
	return s
