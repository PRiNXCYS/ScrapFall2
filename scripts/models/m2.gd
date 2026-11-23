## M2 Browning .50 cal heavy machine gun on a pedestal mount (vehicle and camp gun). Muzzle points +Z.
class_name M2Model
extends RefCounted

const SCALE := 1.6  # the real gun is 1.65 m long; slightly enlarged so it reads from the game camera


## Builds the swivelling head under `head` (the pedestal goes on `base`); returns the part count.
static func build(base: Node3D, head: Node3D) -> int:
	var n := 0
	var post := CylinderMesh.new()
	post.top_radius = 0.05 * SCALE
	post.bottom_radius = 0.08 * SCALE
	post.height = 0.55 * SCALE
	post.radial_segments = 8
	Art.part(base, post, "steel", Vector3(0, 0.27 * SCALE, 0))
	Art.box(base, Vector3(0.4, 0.06, 0.4) * SCALE, "gunmetal", Vector3(0, 0.03 * SCALE, 0))
	n += 2
	var s := SCALE
	var parts: Array = [
		[Vector3(0.1, 0.06, 0.2), "gunmetal", Vector3(0, 0.56, 0)],  # cradle
		[Vector3(0.12, 0.13, 0.5), "gunmetal", Vector3(0, 0.66, 0.02)],  # receiver
		[Vector3(0.125, 0.02, 0.32), "steel", Vector3(0, 0.735, 0.05)],  # top cover
		[Vector3(0.02, 0.05, 0.03), "gunmetal", Vector3(0, 0.76, -0.1)],  # rear leaf sight
		[Vector3(0.02, 0.1, 0.03), "gunmetal", Vector3(-0.05, 0.62, -0.3), Vector3(0.3, 0, 0)],  # spade grips
		[Vector3(0.02, 0.1, 0.03), "gunmetal", Vector3(0.05, 0.62, -0.3), Vector3(0.3, 0, 0)],
		[Vector3(0.12, 0.02, 0.03), "gunmetal", Vector3(0, 0.66, -0.27)],  # butterfly trigger bar
		[Vector3(0.11, 0.15, 0.24), "olive_d", Vector3(-0.14, 0.6, 0.05)],  # .50 ammo can
		[Vector3(0.05, 0.02, 0.12), "line", Vector3(-0.07, 0.69, 0.05)],  # belt into the feed
		[Vector3(0.02, 0.05, 0.02), "gunmetal", Vector3(0, 0.71, 0.92)],  # front sight
	]
	for p in parts:
		Art.box(head, p[0] * s, p[1], p[2] * s, p[3] if p.size() > 3 else Vector3.ZERO)
		n += 1
	var jacket := CylinderMesh.new()  # perforated barrel jacket
	jacket.top_radius = 0.035 * s
	jacket.bottom_radius = 0.035 * s
	jacket.height = 0.22 * s
	jacket.radial_segments = 8
	Art.part(head, jacket, "gunmetal", Vector3(0, 0.66, 0.36) * s, Vector3(PI / 2, 0, 0))
	for k in 4:
		Art.box(head, Vector3(0.075, 0.012, 0.025) * s, "tire", Vector3(0, 0.66, 0.29 + k * 0.045) * s)  # cooling holes
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.018 * s
	barrel.bottom_radius = 0.022 * s
	barrel.height = 0.48 * s
	barrel.radial_segments = 8
	Art.part(head, barrel, "gunmetal", Vector3(0, 0.66, 0.7) * s, Vector3(PI / 2, 0, 0))
	var hider := CylinderMesh.new()
	hider.top_radius = 0.03 * s
	hider.bottom_radius = 0.026 * s
	hider.height = 0.06 * s
	hider.radial_segments = 6
	Art.part(head, hider, "steel", Vector3(0, 0.66, 0.96) * s, Vector3(PI / 2, 0, 0))
	return n + 7


## Where the muzzle is, in head-local space.
static func muzzle() -> Vector3:
	return Vector3(0, 0.66, 1.0) * SCALE
