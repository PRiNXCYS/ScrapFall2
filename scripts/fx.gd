## Short-lived effects: scrap explosions and bullet tracers. Each frees itself.
class_name Fx
extends RefCounted

const MAX_LIGHTS := 2  # phones: flashes are expensive, keep at most two alive
static var _lights := 0


static func explode(parent: Node, at: Vector3, big := true) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 22 if big else 10
	p.lifetime = 1.1
	p.direction = Vector3.UP
	p.spread = 70
	p.initial_velocity_min = 5
	p.initial_velocity_max = 11
	p.gravity = Vector3(0, -22, 0)
	p.angular_velocity_min = -400
	p.angular_velocity_max = 400
	p.scale_amount_min = .5
	p.scale_amount_max = 1.2
	var b := BoxMesh.new()
	b.size = Vector3(.35, .2, .35)
	p.mesh = b
	p.material_override = Art.mat("rust") if randf() < .5 else Art.mat("steel")
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	_free_later(p, 1.4)
	if _lights >= MAX_LIGHTS:
		return
	_lights += 1
	var l := OmniLight3D.new()
	l.tree_exiting.connect(func() -> void: _lights -= 1)
	l.light_color = Color(1, .6, .25)
	l.light_energy = 5.0
	l.omni_range = 8
	parent.add_child(l)
	l.global_position = at
	_free_later(l, 0.18)


static func tracer(parent: Node, a: Vector3, b: Vector3) -> void:
	if a.distance_to(b) < 0.1:
		return
	var m := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(.12, .12, a.distance_to(b))
	m.mesh = bx
	m.material_override = Art.mat("tracer")
	parent.add_child(m)
	m.global_position = (a + b) / 2
	m.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	_free_later(m, 0.05)


static func _free_later(n: Node, secs: float) -> void:
	n.get_tree().create_timer(secs).timeout.connect(func() -> void:
		if is_instance_valid(n):
			n.queue_free())
