## Bram's truck: the low-poly model, driven by a TruckDrive.
class_name Truck
extends Node3D

var drive := TruckDrive.new()
var body: Node3D
var turret_mount: Node3D
var tower_slots: Array[Node3D] = []
var _wheels: Array[Node3D] = []
var _dust: Array[CPUParticles3D] = []


func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	Art.box(body, Vector3(2.8, .6, 9.0), "steel", Vector3(0, 1.0, 0))  # chassis
	Art.box(body, Vector3(2.7, 1.9, 2.6), "rust", Vector3(0, 2.15, 3.2))  # cab
	Art.box(body, Vector3(2.4, .8, .1), "glass", Vector3(0, 2.6, 4.52))  # windscreen
	Art.box(body, Vector3(2.9, .35, .5), "steel", Vector3(0, 1.2, 4.75))  # ram bar
	for i in 5:
		Art.box(body, Vector3(.18, .5, .25), "steel", Vector3(-1.1 + i * .55, 1.45, 4.95))
	Art.box(body, Vector3(2.7, 1.5, 5.4), "rust_d", Vector3(0, 2.0, -1.4))  # cargo box
	for i in 4:
		Art.box(body, Vector3(2.8, .12, .5), "steel", Vector3(0, 2.8, -3.6 + i * 1.5))
	Art.box(body, Vector3(.5, .9, .5), "steel", Vector3(-1.0, 3.0, 2.2))  # exhaust
	var core := CylinderMesh.new()
	core.top_radius = 0.0
	core.bottom_radius = .35
	core.height = 1.0
	core.radial_segments = 6
	Art.part(body, core, "cyan", Vector3(0, 3.3, -3.3))
	var cl := OmniLight3D.new()
	cl.light_color = Color(.3, .9, 1.0)
	cl.light_energy = 2.5
	cl.omni_range = 9
	cl.position = Vector3(0, 3.6, -3.3)
	body.add_child(cl)
	for side in [-1.4, 1.4]:
		for wz in [3.2, -.6, -3.2]:
			_wheel(Vector3(side, .75, wz))
	turret_mount = Node3D.new()
	turret_mount.position = Vector3(0, 2.95, -.4)
	body.add_child(turret_mount)
	for p in [Vector3(-1.0, 2.8, -2.6), Vector3(1.0, 2.8, -2.6), Vector3(-1.0, 2.8, 1.6), Vector3(1.0, 2.8, 1.6)]:
		var s := Node3D.new()
		s.position = p
		body.add_child(s)
		tower_slots.append(s)
	for side in [-1.4, 1.4]:
		_dust.append(_make_dust(Vector3(side, .3, -4.2)))


func _wheel(pos: Vector3) -> void:
	var cy := CylinderMesh.new()
	cy.top_radius = .75
	cy.bottom_radius = .75
	cy.height = .6
	cy.radial_segments = 10
	var w := Node3D.new()
	w.position = pos
	body.add_child(w)
	Art.part(w, cy, "tire", Vector3.ZERO, Vector3(0, 0, PI / 2))
	Art.box(w, Vector3(.62, .5, .5), "steel", Vector3.ZERO)
	_wheels.append(w)


func _make_dust(pos: Vector3) -> CPUParticles3D:
	var d := CPUParticles3D.new()
	d.amount = 24
	d.lifetime = 1.2
	d.position = pos
	d.direction = Vector3(0, .4, -1)
	d.spread = 25
	d.initial_velocity_min = 2
	d.initial_velocity_max = 5
	d.gravity = Vector3(0, .6, 0)
	d.scale_amount_min = .6
	d.scale_amount_max = 1.0
	var sm := SphereMesh.new()
	sm.radius = .4
	sm.height = .8
	sm.radial_segments = 6
	sm.rings = 3
	d.mesh = sm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(.8, .6, .4, .25)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	d.material_override = dm
	d.local_coords = false
	body.add_child(d)
	return d


## Copies the driving state onto the model: position, lean, wheel spin, dust.
func sync(dt: float) -> void:
	position = Vector3(drive.x, 0, drive.z)
	body.rotation.y = drive.steer * 0.18 if not drive.parked else 0.0
	body.rotation.z = -drive.steer * 0.05 if not drive.parked else 0.0
	body.position.y = sin(Time.get_ticks_msec() * 0.02) * 0.04 if not drive.parked else 0.0
	for w in _wheels:
		w.rotation.x += drive.speed * dt / 0.75
	for d in _dust:
		d.emitting = drive.speed > 2.0
