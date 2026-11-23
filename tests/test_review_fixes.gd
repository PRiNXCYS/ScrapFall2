## Fixes from the slice 1 review: two-thumb steering right, no phantom fire on phones, no stuck touches,
## back gesture pauses, fewer draw calls and lights, guns bolted onto the truck.
extends TestCase

var run: Run


func cleanup() -> void:
	tree.paused = false
	if is_instance_valid(run):
		run.free()


func _touch(tc: TouchControls, idx: int, pos: Vector2, down := true) -> void:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.pressed = down
	t.position = pos
	tc.handle(t)


func _run() -> Run:
	run = load("res://scenes/run.tscn").instantiate()
	run.manual = true
	tree.root.add_child(run)
	return run


func test_steer_right_while_boosting() -> void:
	var tc := TouchControls.new()
	tc.size = Vector2(1280, 720)
	_touch(tc, 1, tc.layout(tc.size)["boost"].get_center())
	_touch(tc, 0, Vector2(1280 * 0.4, 500))  # left thumb on the inner (right-steer) zone
	assert_true(tc.steer() < 0.0, "steers right while the right thumb boosts")
	assert_true(tc.boost_held(), "still boosting")
	tc.free()


func test_emulated_mouse_does_not_fire() -> void:
	_run()
	await frames(1)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.device = InputEvent.DEVICE_ID_EMULATION
	run._unhandled_input(ev)
	assert_true(not run.mouse_fire, "a thumb on the stick is not a mouse click")
	var real := InputEventMouseButton.new()
	real.button_index = MOUSE_BUTTON_LEFT
	real.pressed = true
	run._unhandled_input(real)
	assert_true(run.mouse_fire, "a real mouse click fires")


func test_touches_cleared_on_pause() -> void:
	_run()
	await frames(1)
	run.controls.size = Vector2(1280, 720)
	_touch(run.controls, 0, run.controls.layout(run.controls.size)["boost"].get_center())
	assert_true(run.controls.boost_held(), "holding boost")
	run._set_paused(true)
	run._set_paused(false)
	assert_true(not run.controls.boost_held(), "released after a pause")


func test_back_gesture_pauses_not_quits() -> void:
	assert_true(not ProjectSettings.get_setting("application/config/quit_on_go_back", true), "back does not quit")
	_run()
	await frames(1)
	run._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(tree.paused, "back pauses")


func test_road_chunk_is_few_meshes() -> void:
	var road := Road.new()
	tree.root.add_child(road)
	road.setup(3)
	var n := 0
	for c in road.chunk_nodes:
		n += c.find_children("*", "MeshInstance3D", true, false).size()
	road.free()
	assert_true(n <= RoadPlan.CHUNKS * 12, "at most 12 meshes per chunk, got %d total" % n)


func test_skitters_capped() -> void:
	_run()
	await frames(1)
	for i in 200:
		run._spawn_skitter(Vector3(10, 0, 50))
	assert_true(run.skitters.size() <= Run.MAX_SKITTERS, "%d alive" % run.skitters.size())


func test_flash_lights_off_when_idle() -> void:
	var t := Turret.new()
	tree.root.add_child(t)
	var lights := t.find_children("*", "OmniLight3D", true, false)
	assert_true(lights.size() > 0 and not lights[0].visible, "idle flash light is hidden")
	t.free()


func test_explosion_lights_capped() -> void:
	var host := Node3D.new()
	tree.root.add_child(host)
	for i in 10:
		Fx.explode(host, Vector3(i, 0, 0))
	var lights := host.find_children("*", "OmniLight3D", true, false).size()
	host.free()
	assert_true(lights <= Fx.MAX_LIGHTS, "%d explosion lights" % lights)


func test_gun_bolts_onto_truck_slot() -> void:
	_run()
	await frames(1)
	run.camp.scrap = 50
	var slot: Node3D = run.truck.tower_slots[0]
	assert_true(run.place_at(slot.global_position), "tap on a slot")
	assert_eq(run.camp.slots.size(), 1, "slot used")
	assert_eq(run._slot_guns.size(), 1, "a gun is mounted")
	assert_eq(run.camp.scrap, 40, "paid 10")
