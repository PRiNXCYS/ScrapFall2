## Road rules: size, how far ahead it must reach, where props go, when to recentre the world.
class_name RoadPlan
extends RefCounted

const ROAD_W := 16.0
const CHUNK := 60.0
const CHUNKS := 7
const SHIFT_EVERY := 2000.0
const AHEAD := 4  # chunks of road that must exist in front of the truck


## Chunks to append so the road reaches AHEAD chunks past the truck (first_z = centre of the last chunk).
func chunks_needed(truck_z: float, last_z: float) -> int:
	var end := last_z + CHUNK / 2
	var want := truck_z + CHUNK * AHEAD
	return maxi(0, ceili((want - end) / CHUNK))


## Props for one chunk, in chunk-local space, always well off the road.
func prop_layout(seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out: Array[Dictionary] = []
	for i in 16:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var x := side * rng.randf_range(ROAD_W / 2 + 4, 70.0)
		var z := rng.randf_range(-CHUNK / 2, CHUNK / 2)
		var k := rng.randf()
		var kind := "rock" if k < 0.45 else ("cactus" if k < 0.75 else ("wreck" if k < 0.9 else "scrap"))
		out.append({"kind": kind, "pos": Vector3(x, 0, z), "size": rng.randf_range(0.8, 3.2), "rot": rng.randf() * TAU})
	return out


func should_shift(truck_z: float) -> bool:
	return truck_z > SHIFT_EVERY
