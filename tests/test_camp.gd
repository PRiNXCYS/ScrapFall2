## Day/night cycle and the night camp: parking, placement rules, walls, waves.
extends TestCase


func _run_cycle(c: DayCycle, secs: float) -> Dictionary:
	var seen := {"night": 0, "day": 0}
	for i in int(secs * 10):
		c.step(0.1)
		if c.entered_night:
			seen["night"] += 1
		if c.entered_day:
			seen["day"] += 1
	return seen


func test_day_turns_to_night() -> void:
	var c := DayCycle.new()
	var seen := _run_cycle(c, 150.0 + 5.0 + 1.0)
	assert_eq(c.phase, DayCycle.Phase.NIGHT, "night after 150 s day + 5 s dusk")
	assert_eq(seen["night"], 1, "entered_night once")


func test_night_parks_truck() -> void:
	var c := DayCycle.new()
	var d := TruckDrive.new()
	var camp := Camp.new()
	for i in 1600:
		c.step(0.1)
		camp.on_phase(c, d)
	assert_true(d.parked, "parked at night")
	for i in 1000:
		c.step(0.1)
		camp.on_phase(c, d)
	assert_true(not d.parked, "driving again by day")


func test_cannot_place_on_truck() -> void:
	var camp := Camp.new()
	camp.scrap = 100
	assert_true(not camp.place("gun", Vector2i(0, 0)), "truck cell")
	assert_true(not camp.place("gun", Vector2i(-1, -3)), "truck tail cell")
	assert_true(camp.place("gun", Vector2i(3, 0)), "beside the truck")
	assert_true(not camp.place("wall", Vector2i(3, 0)), "occupied")
	assert_true(not camp.place("wall", Vector2i(9, 0)), "outside 14 m")


func test_cannot_place_without_scrap() -> void:
	var camp := Camp.new()
	camp.scrap = 9
	assert_true(not camp.place("gun", Vector2i(3, 0)), "gun costs 10")
	assert_true(camp.place("wall", Vector2i(3, 0)), "wall costs 3")
	assert_eq(camp.scrap, 6, "paid")
	assert_true(camp.slot_place(0, "gun") == false, "slot gun also costs 10")


func test_wall_blocks_skitter_path() -> void:
	var camp := Camp.new()
	camp.scrap = 100
	for z in range(-1, 2):
		camp.place("wall", Vector2i(4, z))  # a wall line at x 8..10 m
	var b := SkitterBrain.new()
	b.pos = Vector3(20, 0, 1)
	var target := Vector3(1, 0, 1)
	var hp0: float = camp.structures[Vector2i(4, 0)]["hp"]
	for i in 120:
		b.step_camp(0.05, target, camp.blocked)
		if b.chewing != Vector3.INF:
			camp.chew(b.chewing, SkitterBrain.CLIMB_DPS * 0.05)
	assert_true(not b.at_target, "never reached the truck")
	assert_true(camp.structures.has(Vector2i(4, 0)) and camp.structures[Vector2i(4, 0)]["hp"] < hp0, "the wall took damage")


func test_wave_grows_each_night() -> void:
	var camp := Camp.new()
	assert_eq(camp.wave(0).size(), 8, "first night")
	assert_eq(camp.wave(2).size(), 16, "third night")
	assert_true(camp.wave(5).size() > camp.wave(2).size(), "keeps growing")
