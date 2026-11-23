## Dev showroom: three truck designs and three first-person gun designs, side by side, for picking one.
## godot --path . --resolution 1920x1080 res://tools/model_preview.tscn -- --shot=<png> --what=trucks|guns
extends Node3D

var what := "trucks"
var shot := ""
var frame := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
		elif a.begins_with("--what="): what = a.substr(7)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.42, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.8, 0.7)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -40, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	Art.box(self, Vector3(80, 0.1, 40), "sand", Vector3(0, -0.05, 0))
	var cam := Camera3D.new()
	add_child(cam)
	if what == "real":
		var m := Node3D.new()
		m.position = Vector3(0.9, 1.0, 0)
		m.rotation.y = -PI / 2
		m.scale = Vector3.ONE * 1.6
		add_child(m)
		M249Model.build(m)
		var b := Node3D.new()
		b.position = Vector3(-1.2, 0, 0)
		b.rotation.y = PI / 2 + 0.3
		add_child(b)
		var h := Node3D.new()
		b.add_child(h)
		M2Model.build(b, h)
		cam.position = Vector3(0, 1.4, -3.4)
		cam.look_at(Vector3(0, 0.95, 0))
		cam.fov = 45
	elif what == "jeep":
		var j := Node3D.new()
		j.rotation.y = deg_to_rad(215)
		add_child(j)
		_jeep_l1(j)
		cam.position = Vector3(0, 4.2, -8.5)
		cam.look_at(Vector3(0, 1.0, 0))
		cam.fov = 45
	elif what == "trucks":
		for i in 3:
			var t := Node3D.new()
			t.position = Vector3((1 - i) * 9.5, 0, 0)
			t.rotation.y = deg_to_rad(215)
			add_child(t)
			[_truck_hauler, _truck_warrig, _truck_crawler][i].call(t)
		cam.position = Vector3(0, 8, -19)
		cam.look_at(Vector3(0, 1.5, 0))
		cam.fov = 55
	else:
		for i in 3:
			var g := Node3D.new()
			g.position = Vector3((1 - i) * 1.25, 1.0, 0)
			g.rotation.y = -PI / 2 - 0.35
			add_child(g)
			[_gun_scrap_rifle, _gun_carbine, _gun_rivet][i].call(g)
		cam.position = Vector3(0, 1.45, -2.3)
		cam.look_at(Vector3(0, 1.0, 0))
		cam.fov = 45


func _process(_d: float) -> void:
	frame += 1
	if frame == 30 and shot != "":
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()


# ------------------------------------------------------------- shared bits

func _wheel(p: Node3D, pos: Vector3, r := 0.75, w := 0.6) -> void:
	var cy := CylinderMesh.new()
	cy.top_radius = r
	cy.bottom_radius = r
	cy.height = w
	cy.radial_segments = 12
	Art.part(p, cy, "tire", pos, Vector3(0, 0, PI / 2))
	var hub := CylinderMesh.new()
	hub.top_radius = r * 0.45
	hub.bottom_radius = r * 0.45
	hub.height = w + 0.04
	hub.radial_segments = 6
	Art.part(p, hub, "steel", pos, Vector3(0, 0, PI / 2))
	for k in 6:  # tread blocks
		var a := k * TAU / 6
		Art.box(p, Vector3(w + 0.02, 0.12, 0.18), "rust_d", pos + Vector3(0, cos(a) * r, sin(a) * r), Vector3(a, 0, 0))


func _core(p: Node3D, pos: Vector3, cage := true) -> void:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.35
	c.height = 1.0
	c.radial_segments = 6
	Art.part(p, c, "cyan", pos + Vector3(0, 0.5, 0))
	Art.box(p, Vector3(1.0, 0.15, 1.0), "steel", pos)
	if cage:
		for k in 4:
			var a := k * TAU / 4 + PI / 4
			Art.box(p, Vector3(0.08, 1.2, 0.08), "steel", pos + Vector3(cos(a) * 0.5, 0.6, sin(a) * 0.5))
		Art.box(p, Vector3(1.0, 0.08, 1.0), "steel", pos + Vector3(0, 1.2, 0))


func _plates(p: Node3D, origin: Vector3, cols: int, rows: int, size: Vector2, side: float) -> void:
	for cx in cols:
		for ry in rows:
			var mat: String = ["rust", "rust_d", "steel"][(cx * 7 + ry * 3) % 3]
			var pos := origin + Vector3(0, ry * size.y, cx * size.x)
			Art.box(p, Vector3(0.06, size.y * 0.92, size.x * 0.92), mat, pos + Vector3(side * 0.03, 0, 0), Vector3(0.03 * ((cx + ry) % 3 - 1), 0, 0))
			for b in [-1, 1]:  # bolts
				Art.box(p, Vector3(0.08, 0.06, 0.06), "steel", pos + Vector3(side * 0.07, size.y * 0.35, b * size.x * 0.38))


# ------------------------------------------------------------- truck A: Bram's Hauler (long-nose road truck)

func _truck_hauler(t: Node3D) -> void:
	Art.box(t, Vector3(2.6, 0.5, 9.2), "steel", Vector3(0, 1.0, 0))
	Art.box(t, Vector3(2.3, 1.1, 2.4), "rust", Vector3(0, 1.8, 3.6))  # long hood
	for i in 6:
		Art.box(t, Vector3(0.12, 0.7, 0.06), "steel", Vector3(-0.75 + i * 0.3, 1.75, 4.82))  # grille bars
	Art.box(t, Vector3(2.5, 0.25, 0.25), "steel", Vector3(0, 1.3, 4.9))
	for x in [-0.85, 0.85]:
		Art.box(t, Vector3(0.45, 0.3, 0.1), "line", Vector3(x, 2.05, 4.82))  # headlights
	Art.box(t, Vector3(2.6, 1.9, 2.0), "rust", Vector3(0, 2.4, 1.6))  # cab
	Art.box(t, Vector3(2.3, 0.8, 0.08), "glass", Vector3(0, 2.85, 2.62))
	Art.box(t, Vector3(0.08, 0.7, 1.2), "glass", Vector3(1.31, 2.8, 1.7))
	Art.box(t, Vector3(0.08, 0.7, 1.2), "glass", Vector3(-1.31, 2.8, 1.7))
	for x in [-1.45, 1.45]:
		Art.box(t, Vector3(0.1, 0.4, 0.25), "steel", Vector3(x, 2.8, 2.6))  # mirrors
		Art.box(t, Vector3(0.25, 2.4, 0.25), "steel", Vector3(x * 0.85, 3.3, 0.55))  # exhaust stacks
		Art.box(t, Vector3(0.35, 0.12, 0.35), "rust_d", Vector3(x * 0.85, 4.55, 0.55))
		Art.box(t, Vector3(0.5, 0.6, 1.6), "steel", Vector3(x * 0.95, 1.25, 0.2))  # fuel tanks
	Art.box(t, Vector3(2.0, 0.18, 0.3), "line", Vector3(0, 3.45, 2.3))  # roof light bar
	Art.box(t, Vector3(2.7, 1.5, 4.6), "rust_d", Vector3(0, 2.0, -2.3))  # cargo box
	_plates(t, Vector3(1.35, 1.55, -4.2), 4, 2, Vector2(1.1, 0.7), 1)
	_plates(t, Vector3(-1.35, 1.55, -4.2), 4, 2, Vector2(1.1, 0.7), -1)
	for i in 3:
		Art.box(t, Vector3(0.6, 0.5, 0.6), "wall", Vector3(-0.7 + i * 0.7, 3.0, -1.0))  # crates
	_core(t, Vector3(0, 2.75, -3.5))
	for side in [-1.35, 1.35]:
		for z in [3.6, -1.2, -3.4]:
			_wheel(t, Vector3(side, 0.8, z))


# ------------------------------------------------------------- truck B: War Rig (welded armour and spikes)

func _truck_warrig(t: Node3D) -> void:
	Art.box(t, Vector3(2.9, 0.6, 9.0), "steel", Vector3(0, 1.1, 0))
	Art.box(t, Vector3(2.8, 2.0, 2.8), "rust_d", Vector3(0, 2.4, 3.0))  # armoured cab
	Art.box(t, Vector3(2.4, 0.22, 0.08), "glass", Vector3(0, 2.9, 4.42))  # slit window
	Art.box(t, Vector3(2.9, 0.15, 0.1), "steel", Vector3(0, 2.75, 4.45))
	_plates(t, Vector3(1.42, 1.7, 1.8), 2, 2, Vector2(1.2, 0.9), 1)
	_plates(t, Vector3(-1.42, 1.7, 1.8), 2, 2, Vector2(1.2, 0.9), -1)
	for i in 7:  # cow-catcher plough
		Art.box(t, Vector3(0.3, 0.9, 0.12), "steel", Vector3(-1.2 + i * 0.4, 1.25, 4.7), Vector3(0.5, 0, 0))
	for i in 5:  # spikes
		Art.box(t, Vector3(0.12, 0.12, 0.7), "steel", Vector3(-1.0 + i * 0.5, 1.5, 5.1))
	for x in [-1.1, 1.1]:
		Art.box(t, Vector3(0.35, 0.35, 0.15), "line", Vector3(x, 1.95, 4.45))
		Art.box(t, Vector3(0.12, 0.6, 0.12), "steel", Vector3(x * 1.32, 3.2, 1.7), Vector3(0, 0, x * 0.4))  # roof spikes
	Art.box(t, Vector3(2.9, 1.7, 5.0), "rust", Vector3(0, 2.15, -1.7))
	_plates(t, Vector3(1.47, 1.6, -4.0), 4, 2, Vector2(1.15, 0.8), 1)
	_plates(t, Vector3(-1.47, 1.6, -4.0), 4, 2, Vector2(1.15, 0.8), -1)
	for i in 6:  # sandbags on the roof
		Art.box(t, Vector3(0.7, 0.3, 0.45), "sand_d", Vector3(-1.0 + (i % 3) * 1.0, 3.15, -0.4 - (i / 3) * 2.6))
	for x in [-1.0, 1.0]:
		Art.box(t, Vector3(0.3, 1.8, 0.3), "steel", Vector3(x, 4.0, 1.9), Vector3(0, 0, x * -0.15))  # exhaust
	_core(t, Vector3(0, 3.0, -3.3))
	for side in [-1.45, 1.45]:
		for z in [3.0, -1.0]:
			_wheel(t, Vector3(side, 0.8, z))
		_wheel(t, Vector3(side * 1.05, 1.0, -3.4), 1.0, 0.8)  # big rear wheels


# ------------------------------------------------------------- truck C: Desert Crawler (6x6 rover, roll cage)

func _truck_crawler(t: Node3D) -> void:
	Art.box(t, Vector3(3.2, 0.7, 8.0), "steel", Vector3(0, 1.3, 0))
	Art.box(t, Vector3(3.0, 0.9, 2.6), "cactus", Vector3(0, 2.0, 2.4))  # sloped nose (army green)
	Art.box(t, Vector3(3.0, 0.15, 2.8), "steel", Vector3(0, 2.5, 2.4), Vector3(-0.25, 0, 0))
	Art.box(t, Vector3(2.6, 0.7, 0.08), "glass", Vector3(0, 2.75, 1.1), Vector3(-0.4, 0, 0))
	for x in [-1.3, 1.3]:
		for y in [1.0, 2.2]:
			Art.box(t, Vector3(0.12, 0.12, 4.8), "steel", Vector3(x, 2.4 + y * 0.5, -0.4))  # roll cage rails
		for z in [1.0, -0.8, -2.6]:
			Art.box(t, Vector3(0.12, 1.3, 0.12), "steel", Vector3(x, 3.0, z))
		Art.box(t, Vector3(0.3, 0.25, 0.15), "line", Vector3(x * 0.7, 2.05, 3.72))
	for z in [1.0, -2.6]:
		Art.box(t, Vector3(2.7, 0.12, 0.12), "steel", Vector3(0, 3.6, z))
	Art.box(t, Vector3(2.4, 0.15, 0.3), "line", Vector3(0, 3.7, 1.0))  # light bar
	Art.box(t, Vector3(2.8, 0.1, 3.2), "steel", Vector3(0, 3.55, -0.8))  # roof rack
	for i in 4:
		Art.box(t, Vector3(0.6, 0.45, 0.6), ["wall", "rust", "cactus"][i % 3], Vector3(-0.9 + i * 0.6, 3.85, -1.6))
	var sp := CylinderMesh.new()
	sp.top_radius = 0.7
	sp.bottom_radius = 0.7
	sp.height = 0.35
	sp.radial_segments = 10
	Art.part(t, sp, "tire", Vector3(0, 1.6, -4.15), Vector3(PI / 2, 0, 0))  # spare tyre
	Art.box(t, Vector3(0.05, 2.2, 0.05), "steel", Vector3(1.2, 4.6, -2.4))  # antenna
	_core(t, Vector3(0, 1.65, -2.6), false)
	Art.box(t, Vector3(3.0, 0.8, 1.6), "cactus", Vector3(0, 2.05, -1.1))
	for side in [-1.6, 1.6]:
		for z in [2.6, 0.0, -2.6]:
			_wheel(t, Vector3(side, 0.9, z), 0.9, 0.7)
			Art.box(t, Vector3(0.75, 0.12, 1.9), "steel", Vector3(side, 1.85, z))  # mudguards


# ------------------------------------------------------------- guns (first-person, with a gloved hand)

func _hand(g: Node3D, pos: Vector3) -> void:
	Art.box(g, Vector3(0.12, 0.1, 0.16), "rust_d", pos)  # glove
	Art.box(g, Vector3(0.1, 0.1, 0.3), "wall", pos + Vector3(0.0, -0.06, -0.22))  # sleeve


func _gun_scrap_rifle(g: Node3D) -> void:
	Art.box(g, Vector3(0.1, 0.12, 0.42), "steel", Vector3(0, 0, 0))  # receiver
	var b := CylinderMesh.new()
	b.top_radius = 0.025
	b.bottom_radius = 0.025
	b.height = 0.6
	b.radial_segments = 8
	Art.part(g, b, "steel", Vector3(0, 0.02, 0.5), Vector3(PI / 2, 0, 0))  # pipe barrel
	Art.box(g, Vector3(0.07, 0.07, 0.08), "rust_d", Vector3(0, 0.02, 0.82))  # muzzle brake
	for z in [0.32, 0.5]:
		Art.box(g, Vector3(0.075, 0.075, 0.04), "line", Vector3(0, 0.02, z))  # tape wraps
	Art.box(g, Vector3(0.08, 0.1, 0.34), "wall", Vector3(0, -0.02, -0.36), Vector3(0.12, 0, 0))  # wooden stock
	Art.box(g, Vector3(0.06, 0.16, 0.08), "rust", Vector3(0, -0.12, 0.08))  # magazine
	Art.box(g, Vector3(0.06, 0.13, 0.06), "wall", Vector3(0, -0.11, -0.1), Vector3(-0.3, 0, 0))  # grip
	var sc := CylinderMesh.new()
	sc.top_radius = 0.03
	sc.bottom_radius = 0.035
	sc.height = 0.24
	sc.radial_segments = 8
	Art.part(g, sc, "glass", Vector3(0, 0.11, 0.05), Vector3(PI / 2, 0, 0))  # bottle scope
	Art.box(g, Vector3(0.03, 0.05, 0.03), "steel", Vector3(0, 0.08, 0.0))
	_hand(g, Vector3(0, -0.13, -0.12))
	_hand(g, Vector3(0, -0.05, 0.34))


func _gun_carbine(g: Node3D) -> void:
	Art.box(g, Vector3(0.11, 0.15, 0.5), "steel", Vector3(0, 0, 0))  # bullpup body
	Art.box(g, Vector3(0.09, 0.07, 0.3), "rust", Vector3(0, 0.02, 0.38))  # handguard
	for z in [0.3, 0.38, 0.46]:
		Art.box(g, Vector3(0.1, 0.02, 0.03), "rust_d", Vector3(0, 0.065, z))  # vents
	var b := CylinderMesh.new()
	b.top_radius = 0.02
	b.bottom_radius = 0.02
	b.height = 0.2
	b.radial_segments = 8
	Art.part(g, b, "steel", Vector3(0, 0.02, 0.6), Vector3(PI / 2, 0, 0))
	Art.box(g, Vector3(0.06, 0.15, 0.07), "rust_d", Vector3(0, -0.13, -0.15))  # mag behind grip
	Art.box(g, Vector3(0.06, 0.13, 0.06), "steel", Vector3(0, -0.11, 0.12), Vector3(-0.25, 0, 0))  # grip
	Art.box(g, Vector3(0.06, 0.06, 0.1), "steel", Vector3(0, 0.11, 0.1))  # red-dot body
	Art.box(g, Vector3(0.03, 0.03, 0.01), "eye", Vector3(0, 0.12, 0.155))  # red dot
	Art.box(g, Vector3(0.1, 0.04, 0.12), "rust", Vector3(0, -0.04, -0.3))  # butt pad
	_hand(g, Vector3(0, -0.14, 0.06))
	_hand(g, Vector3(0, -0.05, 0.38))


func _gun_rivet(g: Node3D) -> void:
	Art.box(g, Vector3(0.16, 0.17, 0.45), "rust_d", Vector3(0, 0, 0))  # chunky body
	var b := CylinderMesh.new()
	b.top_radius = 0.05
	b.bottom_radius = 0.06
	b.height = 0.4
	b.radial_segments = 8
	Art.part(g, b, "steel", Vector3(0, 0.02, 0.42), Vector3(PI / 2, 0, 0))
	for z in [0.3, 0.38, 0.46, 0.54]:  # glowing coils powered by core shards
		var c := CylinderMesh.new()
		c.top_radius = 0.07
		c.bottom_radius = 0.07
		c.height = 0.025
		c.radial_segments = 8
		Art.part(g, c, "cyan", Vector3(0, 0.02, z), Vector3(PI / 2, 0, 0))
	var d := CylinderMesh.new()
	d.top_radius = 0.1
	d.bottom_radius = 0.1
	d.height = 0.09
	d.radial_segments = 10
	Art.part(g, d, "steel", Vector3(0, -0.14, 0.05), Vector3(0, 0, PI / 2))  # drum magazine
	Art.box(g, Vector3(0.07, 0.14, 0.07), "wall", Vector3(0, -0.12, -0.14), Vector3(-0.3, 0, 0))
	Art.box(g, Vector3(0.18, 0.04, 0.2), "steel", Vector3(0, 0.11, -0.05))  # top handle
	for z in [-0.12, 0.02]:
		Art.box(g, Vector3(0.04, 0.06, 0.04), "steel", Vector3(0, 0.09, z))
	_hand(g, Vector3(0, -0.15, -0.16))
	_hand(g, Vector3(0, 0.15, -0.05))


# ------------------------------------------------------------- level 1: the scrap jeep (open 4x4 with a post-mounted gun)

func _jeep_l1(t: Node3D) -> void:
	Art.box(t, Vector3(1.5, 0.35, 3.4), "olive_d", Vector3(0, 0.75, 0))  # chassis
	Art.box(t, Vector3(1.45, 0.55, 1.2), "olive", Vector3(0, 1.15, 1.05))  # flat hood
	for i in 7:
		Art.box(t, Vector3(0.07, 0.42, 0.05), "olive_d", Vector3(-0.45 + i * 0.15, 1.05, 1.68))  # slot grille
	for x in [-0.48, 0.48]:
		var hl := CylinderMesh.new()
		hl.top_radius = 0.1
		hl.bottom_radius = 0.1
		hl.height = 0.06
		hl.radial_segments = 8
		Art.part(t, hl, "line", Vector3(x, 1.15, 1.7), Vector3(PI / 2, 0, 0))  # round headlights
	for x in [-0.78, 0.78]:
		Art.box(t, Vector3(0.38, 0.1, 1.3), "olive", Vector3(x, 1.12, 1.0))  # front fenders
		Art.box(t, Vector3(0.38, 0.1, 0.8), "olive", Vector3(x, 1.12, -1.2))  # rear fenders
		Art.box(t, Vector3(0.12, 0.08, 0.9), "olive_d", Vector3(x * 1.05, 0.85, 0.05))  # side step
	Art.box(t, Vector3(1.6, 0.18, 0.15), "steel", Vector3(0, 0.82, 1.78))  # bumper
	Art.box(t, Vector3(1.45, 0.65, 1.9), "olive", Vector3(0, 1.1, -0.75))  # tub
	Art.box(t, Vector3(1.25, 0.1, 1.7), "olive_d", Vector3(0, 1.42, -0.75))  # tub floor shadow
	for x in [-0.36, 0.36]:
		Art.box(t, Vector3(0.45, 0.12, 0.45), "rust_d", Vector3(x, 1.5, 0.0))  # seats
		Art.box(t, Vector3(0.45, 0.45, 0.1), "rust_d", Vector3(x, 1.72, -0.22))
	Art.box(t, Vector3(1.05, 0.12, 0.4), "rust_d", Vector3(0, 1.5, -1.25))  # rear bench
	var wh := CylinderMesh.new()  # steering wheel
	wh.top_radius = 0.17
	wh.bottom_radius = 0.17
	wh.height = 0.03
	wh.radial_segments = 10
	Art.part(t, wh, "tire", Vector3(0.36, 1.78, 0.42), Vector3(-0.9, 0, 0))
	Art.box(t, Vector3(0.04, 0.04, 0.4), "steel", Vector3(0.36, 1.62, 0.52), Vector3(-0.9, 0, 0))
	for x in [-0.7, 0.7]:  # windscreen frame
		Art.box(t, Vector3(0.06, 0.7, 0.06), "olive_d", Vector3(x, 1.78, 0.62))
	Art.box(t, Vector3(1.46, 0.06, 0.06), "olive_d", Vector3(0, 2.12, 0.62))
	Art.box(t, Vector3(1.36, 0.6, 0.02), "glass", Vector3(0, 1.8, 0.63))
	Art.box(t, Vector3(0.05, 0.62, 0.05), "olive_d", Vector3(0, 1.8, 0.64))
	_wheel(t, Vector3(0, 1.3, -1.82), 0.42, 0.24)  # spare on the back
	t.get_child(t.get_child_count() - 1).rotation = Vector3(0, PI / 2, 0)
	Art.box(t, Vector3(0.3, 0.45, 0.16), "olive_d", Vector3(0.55, 1.15, -1.78))  # jerry can
	for x in [-0.6, 0.6]:
		Art.box(t, Vector3(0.12, 0.1, 0.05), "eye", Vector3(x, 0.98, -1.73))  # tail lights
	# post-mounted machine gun
	Art.box(t, Vector3(0.09, 1.0, 0.09), "steel", Vector3(0, 1.95, -0.45))
	Art.box(t, Vector3(0.22, 0.2, 0.42), "steel", Vector3(0, 2.5, -0.38))  # receiver
	Art.box(t, Vector3(0.18, 0.16, 0.2), "olive_d", Vector3(0.18, 2.44, -0.38))  # ammo box
	var b := CylinderMesh.new()
	b.top_radius = 0.035
	b.bottom_radius = 0.045
	b.height = 1.0
	b.radial_segments = 8
	Art.part(t, b, "steel", Vector3(0, 2.52, 0.3), Vector3(PI / 2, 0, 0))
	Art.box(t, Vector3(0.1, 0.1, 0.12), "steel", Vector3(0, 2.52, 0.82))
	Art.box(t, Vector3(0.06, 0.16, 0.06), "steel", Vector3(0, 2.38, -0.62), Vector3(-0.4, 0, 0))  # grip
	for x in [-0.55, 0.55]:
		for z in [1.05, -1.2]:
			_wheel(t, Vector3(x * 1.32, 0.45, z), 0.42, 0.26)
	for i in 4:  # rust and scrap patches: this one was dug out of the sand
		Art.box(t, Vector3(0.02, 0.18, 0.25), "rust", Vector3(0.73, 1.05 + (i % 2) * 0.15, -0.3 - i * 0.35))
