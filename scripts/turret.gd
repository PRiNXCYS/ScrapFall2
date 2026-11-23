## A gun that aims and fires by itself: the truck's roof gun, and camp towers via configure().
class_name Turret
extends Node3D

var fire_every := 0.16
var damage := 1.0
var gun_range := 30.0
var shots := 0
var kills := 0
var _fire_t := 0.0
var _head: Node3D
var _muzzle: Node3D
var _flash: OmniLight3D


func configure(every: float, dmg: float, rng: float) -> void:
	fire_every = every
	damage = dmg
	gun_range = rng


func _ready() -> void:
	_head = Node3D.new()
	add_child(_head)
	Art.box(_head, Vector3(1.3, .6, 1.3), "steel", Vector3(0, .3, 0))
	Art.box(_head, Vector3(.3, .3, 2.2), "steel", Vector3(-.25, .55, 1.1))
	Art.box(_head, Vector3(.3, .3, 2.2), "steel", Vector3(.25, .55, 1.1))
	_muzzle = Node3D.new()
	_muzzle.position = Vector3(0, .55, 2.3)
	_head.add_child(_muzzle)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1, .8, .4)
	_flash.omni_range = 7
	_flash.light_energy = 0.0
	_muzzle.add_child(_flash)


func tick(dt: float, brains: Array) -> void:
	_fire_t -= dt
	_flash.light_energy = maxf(0.0, _flash.light_energy - dt * 60.0)
	var target := Targeting.pick(global_position, brains, gun_range)
	if target == null:
		return
	var tp := target.pos + Vector3(0, .9, 0)
	var flat := Vector3(tp.x, global_position.y, tp.z)
	if flat.distance_to(global_position) > 0.3:
		var want := atan2(flat.x - global_position.x, flat.z - global_position.z)
		_head.global_rotation.y = lerp_angle(_head.global_rotation.y, want, 1.0 - exp(-14.0 * dt))
	if _fire_t <= 0.0:
		_fire_t = fire_every
		shots += 1
		Fx.tracer(get_tree().root, _muzzle.global_position, tp)
		_flash.light_energy = 4.0
		if target.hit(damage):
			kills += 1
