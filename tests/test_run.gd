## The whole run: a full day/night/day, two-thumb touch, pausing, HUD on odd screens, radio.
extends TestCase

var run: Run


func cleanup() -> void:
	tree.paused = false
	if is_instance_valid(run):
		run.free()


func test_full_day_night_day() -> void:
	run = load("res://scenes/run.tscn").instantiate()
	run.manual = true
	run.invincible = true
	tree.root.add_child(run)
	await frames(1)
	var parked_at_night := false
	for i in int(260.0 * 20):
		run.step(1.0 / 20.0)
		if run.cycle.phase == DayCycle.Phase.NIGHT and run.truck.drive.parked:
			parked_at_night = true
	assert_true(run.phase_log.has("NIGHT") and run.phase_log.has("DAY"), "phases seen: %s" % str(run.phase_log))
	assert_true(parked_at_night, "parked during the night")
	assert_true(run.cycle.phase == DayCycle.Phase.DAY and not run.truck.drive.parked, "driving again after dawn")


func test_steer_and_boost_together() -> void:
	var tc := TouchControls.new()
	tc.size = Vector2(1280, 720)
	tc.mode = "drive"
	var r: Dictionary = tc.layout(tc.size)
	var t0 := InputEventScreenTouch.new()
	t0.index = 0
	t0.pressed = true
	t0.position = Vector2(150, 500)
	var t1 := InputEventScreenTouch.new()
	t1.index = 1
	t1.pressed = true
	t1.position = r["boost"].get_center()
	tc.handle(t0)
	tc.handle(t1)
	assert_true(tc.steer() > 0.0, "left thumb steers left")
	assert_true(tc.boost_held(), "right thumb boosts")
	tc.free()


func test_focus_out_pauses() -> void:
	run = load("res://scenes/run.tscn").instantiate()
	run.manual = true
	tree.root.add_child(run)
	await frames(1)
	run._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(tree.paused, "paused when the app goes to the background")


func test_hud_fits_aspects() -> void:
	var tc := TouchControls.new()
	for sz in [Vector2(2400, 1080), Vector2(1024, 768), Vector2(1280, 720)]:
		for m in ["drive", "foot", "camp"]:
			tc.mode = m
			var r: Dictionary = tc.layout(sz)
			for k in r:
				var rect: Rect2 = r[k]
				assert_true(Rect2(Vector2.ZERO, sz).encloses(rect), "%s %s inside %s" % [m, k, sz])
				assert_true(rect.size.y >= 64.0, "%s %s tall enough at %s" % [m, k, sz])
	tc.free()


func test_radio_types_and_queues() -> void:
	var r := Radio.new()
	r.say("MARA", "Hello Keeper")
	r.say("TEO", "Second")
	var s := r.step(0.1)
	assert_eq(s["who"], "MARA", "first speaker")
	assert_eq(s["text"], "Hello", "typed 45 chars/s -> 4.5 chars after 0.1 s")
	for i in 40:
		s = r.step(0.1)
	assert_eq(s["who"], "TEO", "queue moves on")
	assert_eq(Radio.voice_path("x"), "res://voice/%s.ogg" % "x".md5_text().substr(0, 10), "voice file name")


func test_controls_and_hud_fill_the_screen() -> void:
	run = load("res://scenes/run.tscn").instantiate()
	run.manual = true
	tree.root.add_child(run)
	await frames(2)
	var vp := run.get_viewport().get_visible_rect().size
	assert_true(run.controls.size.is_equal_approx(vp), "controls %s vs %s" % [run.controls.size, vp])
	assert_true(run.hud.size.is_equal_approx(vp), "hud %s vs %s" % [run.hud.size, vp])


func test_stop_is_survivable() -> void:
	run = load("res://scenes/run.tscn").instantiate()
	run.manual = true
	tree.root.add_child(run)
	await frames(1)
	run.next_stop = 0.0
	for i in 200:
		run.step(1.0 / 20.0)
		if run.mode == "foot":
			break
	assert_eq(run.mode, "foot", "got out at the scrap yard")
	var road_left := run.skitters.filter(func(s): return s.brain.spd > 10.0).size()
	assert_eq(road_left, 0, "road Skitters do not follow you in")
	for i in 100:  # 5 s standing still, not shooting
		run.step(1.0 / 20.0)
	assert_true(run.player != null and run.player.hp > 0.0, "still alive after 5 s, hp %s" % (run.player.hp if run.player else -1.0))
