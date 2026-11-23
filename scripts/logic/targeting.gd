## Who a gun shoots at: climbers on the truck first (their distance counts 5x less), then the nearest.
class_name Targeting
extends RefCounted


static func pick(from: Vector3, brains: Array, max_range := 30.0) -> SkitterBrain:
	var best: SkitterBrain = null
	var bd := INF
	for b in brains:
		if b.state == SkitterBrain.State.DEAD or b.state == SkitterBrain.State.GONE:
			continue
		var d: float = from.distance_to(b.pos)
		if d > max_range:
			continue
		if b.state == SkitterBrain.State.ON_TRUCK:
			d *= 0.2
		if d < bd:
			bd = d
			best = b
	return best
