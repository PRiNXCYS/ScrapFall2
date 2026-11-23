## Phone-friendly aiming: the live Skitter closest to where you look, inside a narrow cone.
class_name AimAssist
extends RefCounted


static func pick(eye: Vector3, forward: Vector3, brains: Array, cone_deg := 12.0, max_dist := 40.0) -> SkitterBrain:
	var best: SkitterBrain = null
	var best_angle := deg_to_rad(cone_deg)
	var f := forward.normalized()
	for b in brains:
		if b.state == SkitterBrain.State.DEAD or b.state == SkitterBrain.State.GONE:
			continue
		var to: Vector3 = (b.pos + Vector3(0, 0.9, 0)) - eye
		if to.length() > max_dist or to.length() < 0.01:
			continue
		var flat := Vector3(to.x, 0, to.z)
		var a := Vector3(f.x, 0, f.z).angle_to(flat)
		if a < best_angle:
			best_angle = a
			best = b
	return best
