## M249 light machine gun (first-person view model) with gloved hands. Built in metres; muzzle points -Z.
class_name M249Model
extends RefCounted


## Builds the gun under `g` and returns how many parts it used (before merging).
static func build(g: Node3D) -> int:
	var n := 0
	var parts: Array = [
		# receiver, feed cover, feed tray, ejection port
		[Vector3(0.075, 0.11, 0.34), "gunmetal", Vector3(0, 0, 0)],
		[Vector3(0.08, 0.035, 0.2), "gunmetal", Vector3(0, 0.07, 0.04)],
		[Vector3(0.05, 0.02, 0.06), "polymer", Vector3(0, 0.095, 0.0)],
		[Vector3(0.012, 0.04, 0.07), "steel", Vector3(0.04, 0.0, 0.02)],
		# rear sight
		[Vector3(0.03, 0.035, 0.02), "gunmetal", Vector3(0, 0.1, 0.12)],
		# pistol grip + trigger guard
		[Vector3(0.045, 0.11, 0.05), "polymer", Vector3(0, -0.1, 0.1), Vector3(-0.3, 0, 0)],
		[Vector3(0.012, 0.01, 0.07), "gunmetal", Vector3(0, -0.065, 0.03)],
		# buttstock (solid polymer) + butt plate
		[Vector3(0.05, 0.09, 0.26), "polymer", Vector3(0, -0.02, 0.29), Vector3(0.08, 0, 0)],
		[Vector3(0.055, 0.12, 0.025), "gunmetal", Vector3(0, -0.035, 0.42)],
		# handguard under the barrel, gas cylinder
		[Vector3(0.07, 0.06, 0.2), "polymer", Vector3(0, -0.035, -0.26)],
		[Vector3(0.025, 0.025, 0.3), "gunmetal", Vector3(0, -0.045, -0.4)],
		# barrel carry handle
		[Vector3(0.015, 0.05, 0.015), "gunmetal", Vector3(0, 0.05, -0.3)],
		[Vector3(0.015, 0.015, 0.12), "gunmetal", Vector3(0, 0.075, -0.33)],
		# front sight post
		[Vector3(0.012, 0.05, 0.012), "gunmetal", Vector3(0, 0.035, -0.62)],
		# folded bipod legs
		[Vector3(0.012, 0.012, 0.22), "gunmetal", Vector3(-0.02, -0.07, -0.45)],
		[Vector3(0.012, 0.012, 0.22), "gunmetal", Vector3(0.02, -0.07, -0.45)],
		# 200-round soft ammo pouch on the left, belt into the feed tray
		[Vector3(0.09, 0.11, 0.12), "pouch", Vector3(-0.07, -0.1, -0.03)],
		[Vector3(0.03, 0.02, 0.05), "line", Vector3(-0.03, -0.035, -0.03)],
	]
	for p in parts:
		Art.box(g, p[0], p[1], p[2], p[3] if p.size() > 3 else Vector3.ZERO)
		n += 1
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.012
	barrel.bottom_radius = 0.014
	barrel.height = 0.48
	barrel.radial_segments = 8
	Art.part(g, barrel, "gunmetal", Vector3(0, 0.01, -0.42), Vector3(PI / 2, 0, 0))
	var hider := CylinderMesh.new()  # birdcage flash hider
	hider.top_radius = 0.018
	hider.bottom_radius = 0.018
	hider.height = 0.05
	hider.radial_segments = 6
	Art.part(g, hider, "steel", Vector3(0, 0.01, -0.68), Vector3(PI / 2, 0, 0))
	n += 2
	n += _hand(g, Vector3(0.0, -0.13, 0.08), false)  # right hand on the grip
	n += _hand(g, Vector3(0.0, -0.075, -0.27), true)  # left hand under the handguard
	return n


## A gloved hand: palm, four fingers, thumb, cuff and sleeve.
static func _hand(g: Node3D, at: Vector3, support: bool) -> int:
	var n := 0
	Art.box(g, Vector3(0.09, 0.05, 0.1), "glove", at)
	for i in 4:
		Art.box(g, Vector3(0.018, 0.022, 0.06), "glove", at + Vector3(-0.03 + i * 0.02, 0.03 if support else -0.01, -0.06 if support else 0.05))
		n += 1
	Art.box(g, Vector3(0.022, 0.022, 0.06), "glove", at + Vector3(0.05, 0.03, -0.01))
	Art.box(g, Vector3(0.095, 0.06, 0.05), "steel", at + Vector3(0, -0.005, 0.07))  # wrist cuff
	Art.box(g, Vector3(0.11, 0.1, 0.32), "sleeve", at + Vector3(0, -0.03, 0.25), Vector3(0.25, 0, 0))
	return n + 4
