## One run of SCRAPFALL 2: drive by day, stop to explore on foot, dig in and defend at night.
## Keys: A/D or arrows steer, SPACE boost, C camera, E stop / get back in, WASD + mouse on foot, click fire.
## Dev flags (after --): --shot=<png> --shot-after=<frames> --cam=<0|1|2> --night --stop --invincible
class_name Run
extends Node3D

const STOP_EVERY := 1500.0
const STOP_REACH := 20.0
const PLAYER_HIT_DPS := 8.0
const DAWN_BONUS := 10
const MAX_SKITTERS := 40  # phones: cap what is alive at once
const SLOT_REACH := 1.6
const FOOT_SKITTER_SPEED := Vector2(4.0, 6.0)  # on foot they walk; on the road they sprint

var mouse_fire := false  # a real mouse button, not a finger emulated as one
var manual := false  # tests call step() themselves
var invincible := false
var phase_log: Array[String] = []

var rng := RandomNumberGenerator.new()
var road: Road
var truck: Truck
var roof_gun: Turret
var cam: CameraRig
var cycle := DayCycle.new()
var camp := Camp.new()
var camp_view: CampView
var spawner := Spawner.new()
var radio := Radio.new()
var hud: Hud
var controls: TouchControls
var skitters: Array[Skitter] = []
var mode := "drive"  # drive | foot | camp
var dist := 0.0
var dead := false
var player: PlayerFP
var site: StopSite
var next_stop := STOP_EVERY
var build_left := 0.0
var wave_spawned := false
var lines := {}
var _sun: DirectionalLight3D
var _env: Environment
var _shot_path := ""
var _shot_after := -1
var _frame := 0
var _slot_guns: Array[Turret] = []
var _showcase := false  # dev: a ready-made camp for screenshots


func _ready() -> void:
	rng.seed = 7
	_read_flags()
	lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/radio.json"))
	_make_world()
	road = Road.new()
	add_child(road)
	road.setup(7)
	truck = Truck.new()
	add_child(truck)
	roof_gun = Turret.new()
	truck.turret_mount.add_child(roof_gun)
	cam = CameraRig.new()
	add_child(cam)
	camp_view = CampView.new()
	add_child(camp_view)
	camp_view.setup(camp)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	controls = TouchControls.new()
	layer.add_child(controls)
	controls.pressed.connect(_on_button)
	controls.tapped.connect(_on_tap)
	hud.retry.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene())
	hud.resume.connect(func() -> void: _set_paused(false))
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_say("start")
	for i in 6:
		_spawn_skitter(spawner.spawn_pos(rng, truck.drive.z))
	_apply_flags()
	truck.sync(0.0)
	cam.follow(truck, 0.016)


func _read_flags() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): _shot_path = a.substr(7)
		elif a.begins_with("--shot-after="): _shot_after = int(a.substr(13))
		elif a == "--invincible": invincible = true


func _apply_flags() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cam="):
			for i in int(a.substr(6)):
				cam.cycle_drive_mode()
		elif a == "--night":
			cycle.t = DayCycle.DAY_SECONDS - 0.5
			camp.scrap = 60
		elif a == "--stop":
			next_stop = 0.0
		elif a == "--showcase":
			_showcase = true
		elif a == "--clean":  # dev: no HUD or buttons (promo screenshots)
			hud.visible = false
			controls.visible = false


# ------------------------------------------------------------------ world

func _make_world() -> void:
	_env = Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.18, 0.38, 0.72)
	sm.sky_horizon_color = Color(0.95, 0.66, 0.42)
	sm.ground_horizon_color = Color(0.9, 0.7, 0.5)
	sm.ground_bottom_color = Color(0.6, 0.45, 0.3)
	sky.sky_material = sm
	_env.sky = sky
	_env.background_mode = Environment.BG_SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.35
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 0.85
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.85, 0.62, 0.45)
	_env.fog_density = 0.0035
	_env.glow_enabled = true
	_env.glow_intensity = 0.5
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-50, -35, 0)
	_sun.light_color = Color(1.0, 0.9, 0.75)
	_sun.light_energy = 1.1
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 90.0
	add_child(_sun)


func _light() -> void:
	var e := cycle.light_energy()
	_sun.light_energy = e
	var night := 1.0 - clampf((e - 0.15) / 0.95, 0.0, 1.0)
	_env.ambient_light_energy = lerpf(0.35, 0.12, night)
	_env.fog_light_color = Color(0.85, 0.62, 0.45).lerp(Color(0.1, 0.12, 0.25), night)
	_sun.light_color = Color(1.0, 0.9, 0.75).lerp(Color(0.55, 0.65, 1.0), night)


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	_frame += 1
	if _shot_after >= 0 and _frame == _shot_after:
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()
	if not manual:
		step(minf(delta, 0.1))


func step(dt: float) -> void:
	hud.show_radio(radio.step(dt))
	if dead:
		cam.follow(truck, dt)
		return
	var prev := cycle.phase
	cycle.step(dt)
	if cycle.phase != prev:
		phase_log.append(DayCycle.Phase.keys()[cycle.phase])
	if mode == "foot" and cycle.entered_night:
		_end_stop(true)
	camp.on_phase(cycle, truck.drive)
	if cycle.entered_night:
		_begin_night()
	elif cycle.entered_day:
		_begin_day()
	if cycle.phase == DayCycle.Phase.DUSK and prev == DayCycle.Phase.DAY:
		_say("dusk")
	_light()
	match mode:
		"drive": _step_drive(dt)
		"foot": _step_foot(dt)
		"camp": _step_camp(dt)
	truck.sync(dt)
	for s in skitters:
		s.sync(dt, truck)
	_refresh_climbers()
	var brains := _brains()
	roof_gun.tick(dt, brains)
	for g in _slot_guns:
		g.tick(dt, brains)
	if mode == "camp":
		camp_view.tick(dt, brains)
	_reap()
	if mode == "foot":
		cam.follow(player, dt)
	else:
		cam.follow(truck, dt, truck.drive.boosting)
	controls.mode = mode
	controls.show_start = mode == "camp" and not wave_spawned
	controls.queue_redraw()
	_hud()
	if invincible:
		truck.drive.hp = TruckDrive.MAX_HP
	if truck.drive.dead() or (player != null and player.hp <= 0.0):
		_die()


func _step_drive(dt: float) -> void:
	var s := controls.steer()
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): s += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): s -= 1.0
	var boost := controls.boost_held() or Input.is_key_pressed(KEY_SPACE)
	var before := truck.drive.z
	truck.drive.step(dt, clampf(s, -1.0, 1.0), boost)
	dist += truck.drive.z - before
	road.follow(truck.drive.z)
	if road.plan.should_shift(truck.drive.z):
		_shift(-RoadPlan.SHIFT_EVERY)
	if cycle.phase == DayCycle.Phase.DAY:
		var n := spawner.due(dt, dist)
		for i in n:
			_spawn_skitter(spawner.spawn_pos(rng, truck.drive.z))
		if spawner.swarm_now:
			_say("swarm")
	for s2 in skitters:
		var was := s2.brain.state
		s2.brain.step(dt, truck.drive)
		if s2.brain.state == SkitterBrain.State.DEAD and was != SkitterBrain.State.DEAD and s2.brain.rammed:
			cam.shake(0.5)
		elif s2.brain.state == SkitterBrain.State.ON_TRUCK and was == SkitterBrain.State.RUN:
			cam.shake(0.35)
	_maybe_site()
	controls.show_stop = site != null and absf(site.position.z - truck.drive.z) < STOP_REACH


func _step_foot(dt: float) -> void:
	var mv := controls.stick()
	if Input.is_key_pressed(KEY_W): mv.y += 1.0
	if Input.is_key_pressed(KEY_S): mv.y -= 1.0
	if Input.is_key_pressed(KEY_A): mv.x -= 1.0
	if Input.is_key_pressed(KEY_D): mv.x += 1.0
	player.move_input(mv)
	player.look_input(controls.take_look())
	player.tick(dt)
	var brains := _brains()
	if controls.fire_held() or mouse_fire:
		player.fire(brains)
	var got := site.loot_near(player.global_position)
	if got > 0:
		camp.scrap += got
		radio.say("TEO", "+%d scrap. Good find." % got)
	for s in skitters:
		if s.brain.state != SkitterBrain.State.RUN:
			continue
		s.brain.step_camp(dt, player.global_position, Callable())
		if s.brain.at_target:
			player.hp -= PLAYER_HIT_DPS * dt
	controls.show_board = player.global_position.distance_to(truck.global_position) < StopRules.BOARD_DIST + 2.0


func _step_camp(dt: float) -> void:
	if not wave_spawned:
		build_left -= dt
		if build_left <= 0.0:
			_start_wave()
	for s in skitters:
		if s.brain.state != SkitterBrain.State.RUN:
			continue
		s.brain.step_camp(dt, truck.global_position, camp.blocked)
		if s.brain.chewing != Vector3.INF:
			if camp.chew(s.brain.chewing, SkitterBrain.CLIMB_DPS * dt):
				camp_view.refresh()
		elif s.brain.at_target:
			s.brain.state = SkitterBrain.State.ON_TRUCK
		s.brain.pos.y = 0.0
	for s in skitters:
		if s.brain.state == SkitterBrain.State.ON_TRUCK:
			truck.drive.damage(SkitterBrain.CLIMB_DPS * dt)
	if wave_spawned and skitters.is_empty() and cycle.phase == DayCycle.Phase.NIGHT and not _showcase:
		cycle.skip_to_dawn()
		camp.scrap += DAWN_BONUS
		phase_log.append("DAWN")


# ------------------------------------------------------------------ phases

func _begin_night() -> void:
	_clear_skitters()
	mode = "camp"
	cam.set_drive_mode(CameraRig.Mode.TOPDOWN)
	build_left = Camp.BUILD_SECONDS
	wave_spawned = false
	if _showcase:
		camp.scrap = 400
		for c in [Vector2i(3, -3), Vector2i(-4, -3), Vector2i(3, 3), Vector2i(-4, 3), Vector2i(0, 5), Vector2i(-1, -6)]:
			camp.place("gun", c)
		for x in range(-5, 5):
			camp.place("wall", Vector2i(x, 6))
			camp.place("wall", Vector2i(x, -7))
		for z in range(-6, 6):
			camp.place("wall", Vector2i(5, z))
			camp.place("wall", Vector2i(-6, z))
		camp_view.refresh()
		for s2 in truck.tower_slots:
			place_at(s2.global_position)
		build_left = 1.0


func _start_wave() -> void:
	wave_spawned = true
	for p in camp.wave(cycle.nights - 1):
		_spawn_skitter(p)


func _begin_day() -> void:
	_clear_skitters()
	camp_view.clear()
	mode = "drive"
	cam.set_drive_mode(CameraRig.Mode.CHASE)
	_say("dawn")


func _maybe_site() -> void:
	if site == null and dist >= next_stop and cycle.phase == DayCycle.Phase.DAY:
		site = StopSite.new()
		add_child(site)
		site.position = Vector3(RoadPlan.ROAD_W / 2 + 18.0, 0, truck.drive.z + 90.0)
		_say("stop")
	elif site != null and mode == "drive" and site.position.z < truck.drive.z - 60.0:
		site.queue_free()
		site = null
		next_stop = dist + STOP_EVERY
	if site != null and mode == "drive" and next_stop <= 0.0 and absf(site.position.z - truck.drive.z) < STOP_REACH:
		_begin_stop()  # dev flag --stop drives straight in


func _begin_stop() -> void:
	if site == null:
		return
	mode = "foot"
	next_stop = dist + STOP_EVERY
	player = PlayerFP.new()
	add_child(player)
	player.global_position = truck.global_position + Vector3(2.5, 0, 0)
	player.rotation.y = -PI / 2  # face the scrap yard (+x)
	StopRules.begin_stop(truck.drive, cam, player.head)
	_clear_skitters()  # the road pack does not follow you into the yard
	for p in site.skitter_spots:
		_spawn_skitter(site.to_global(p))
		skitters[-1].brain.spd = rng.randf_range(FOOT_SKITTER_SPEED.x, FOOT_SKITTER_SPEED.y)


func _end_stop(force := false) -> void:
	if player == null:
		return
	if not force and not StopRules.try_end_stop(truck.drive, cam, player.global_position, truck.global_position):
		return
	if force:
		truck.drive.parked = false
		cam.set_drive_mode(CameraRig.Mode.CHASE)
	player.queue_free()
	player = null
	mode = "drive"
	_clear_skitters()


func _die() -> void:
	dead = true
	Fx.explode(self, truck.global_position + Vector3(0, 2, 0))
	_say("dead")
	hud.game_over(dist, camp.scrap)


# ------------------------------------------------------------------ helpers

func _spawn_skitter(at: Vector3) -> void:
	if skitters.size() >= MAX_SKITTERS:
		return
	var s := Skitter.new()
	s.brain.pos = at
	s.brain.spd = rng.randf_range(15.0, 21.0)
	add_child(s)
	s.position = at
	skitters.append(s)


func _brains() -> Array:
	return skitters.map(func(s): return s.brain)


func _refresh_climbers() -> void:
	for s in skitters:
		if s.brain.state == SkitterBrain.State.ON_TRUCK and s.is_inside_tree():
			s.brain.pos = s.global_position


func _reap() -> void:
	for s in skitters.duplicate():
		match s.brain.state:
			SkitterBrain.State.DEAD:
				Fx.explode(self, s.global_position + Vector3(0, 1, 0))
				camp.scrap += rng.randi_range(1, 3)
				skitters.erase(s)
				s.queue_free()
			SkitterBrain.State.GONE:
				skitters.erase(s)
				s.queue_free()


func _clear_skitters() -> void:
	for s in skitters:
		s.queue_free()
	skitters.clear()


func _shift(dz: float) -> void:
	truck.drive.z += dz
	road.shift(dz)
	for s in skitters:
		s.brain.pos.z += dz
		if s.get_parent() == self:
			s.position.z += dz
	if site != null:
		site.position.z += dz
	camp.origin.z += dz


func _say(key: String) -> void:
	var opts: Array = lines.get(key, [])
	if opts.is_empty():
		return
	if key == "start":
		for l in opts:
			radio.say(l[0], l[1])
	else:
		var l: Array = opts[rng.randi() % opts.size()]
		radio.say(l[0], l[1])


func _hud() -> void:
	var extra := ""
	var climbers := skitters.filter(func(s): return s.brain.state == SkitterBrain.State.ON_TRUCK).size()
	if climbers > 0:
		extra = "CLIMBERS: %d" % climbers
	if mode == "foot":
		extra = "KEEPER %d / %d    crates left %d" % [int(player.hp), int(PlayerFP.MAX_HP), site.loot_left()]
	hud.show_state(truck.drive.hp, truck.drive.boost, dist, camp.scrap, extra)
	match mode:
		"camp":
			if not wave_spawned:
				hud.banner("NIGHT %d  -  build your camp  %d" % [cycle.nights, ceili(build_left)])
			else:
				hud.banner("NIGHT %d  -  hold until dawn  (%d left)" % [cycle.nights, skitters.size()])
		"foot":
			hud.banner("SCRAP YARD  -  loot the crates, then get back in")
		_:
			hud.banner("STOP AHEAD" if controls.show_stop else "")


func _on_button(name: String) -> void:
	match name:
		"cam": cam.cycle_drive_mode()
		"stop": _begin_stop()
		"board": _end_stop()
		"start":
			if mode == "camp" and not wave_spawned:
				_start_wave()
		"gun", "wall": camp_view.selected = name


func _on_tap(at: Vector2) -> void:
	if mode != "camp":
		return
	var from := cam.project_ray_origin(at)
	var dir := cam.project_ray_normal(at)
	if absf(dir.y) < 0.001:
		return
	var hit := from + dir * (-from.y / dir.y)
	camp_view.hover(hit)
	place_at(hit)


## Camp build at a world point: a truck slot if you tapped one, otherwise the ground grid.
func place_at(world: Vector3) -> bool:
	for i in truck.tower_slots.size():
		var sp := truck.tower_slots[i].global_position
		if Vector2(sp.x - world.x, sp.z - world.z).length() <= SLOT_REACH:
			if not camp.slot_place(i, "gun"):
				return false
			var g := Turret.new()
			g.configure(0.25, 1.0, 26.0)
			truck.tower_slots[i].add_child(g)
			_slot_guns.append(g)
			return true
	return camp_view.try_place(world)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_C: if mode != "foot": cam.cycle_drive_mode()
			KEY_E:
				if mode == "drive" and controls.show_stop: _begin_stop()
				elif mode == "foot": _end_stop()
			KEY_ESCAPE, KEY_P: _set_paused(not get_tree().paused)
			KEY_R: if dead: hud.retry.emit()
			KEY_1: camp_view.selected = "gun"
			KEY_2: camp_view.selected = "wall"
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.device != InputEvent.DEVICE_ID_EMULATION:
		mouse_fire = ev.pressed
	if ev is InputEventMouseMotion and mode == "foot" and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		player.look_input(ev.relative)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_set_paused(true)


func _set_paused(on: bool) -> void:
	if not is_inside_tree():
		return
	get_tree().paused = on
	hud.set_paused(on)
	controls.release_all()
