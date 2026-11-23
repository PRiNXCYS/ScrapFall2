## The Keeper on foot: first-person walk, look and shoot (with aim assist on phones).
class_name PlayerFP
extends CharacterBody3D

const MOVE_SPEED := 6.0
const FIRE_EVERY := 0.2
const DAMAGE := 2.0
const MAX_HP := 60.0
const LOOK_SENS := 0.004

var hp := MAX_HP
var head: Node3D
var _move := Vector2.ZERO
var _fire_t := 0.0
var _gun: Node3D
var _flash: OmniLight3D
var gun_parts := 0
var gun_rest := Vector3(0.24, -0.2, -0.5)  # where the M249 sits in view
var _kick := 0.0


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)
	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	_gun = Node3D.new()
	_gun.position = gun_rest
	head.add_child(_gun)
	gun_parts = M249Model.build(_gun)
	Art.merge(_gun, true, false)
	_flash = OmniLight3D.new()
	_flash.light_color = Color(1, .8, .4)
	_flash.omni_range = 6
	_flash.light_energy = 0.0
	_flash.visible = false
	_flash.position = Vector3(0, 0.01, -0.72)
	_gun.add_child(_flash)


func move_input(v: Vector2) -> void:
	_move = v.limit_length(1.0)


func look_input(d: Vector2) -> void:
	rotation.y -= d.x * LOOK_SENS
	head.rotation.x = clampf(head.rotation.x - d.y * LOOK_SENS, -1.2, 1.2)


func gun_node() -> Node3D:
	return _gun


func forward() -> Vector3:
	return -head.global_transform.basis.z  # cameras look along -Z


## Fires at the aim-assisted target if there is one; returns the brain that was hit (or null).
func fire(brains: Array) -> SkitterBrain:
	if _fire_t > 0.0:
		return null
	_fire_t = FIRE_EVERY
	_flash.light_energy = 4.0
	_flash.visible = true
	_kick = 1.0
	var eye := head.global_position
	var target := AimAssist.pick(eye, forward(), brains)
	var end := eye + forward() * 40.0
	if target != null:
		end = target.pos + Vector3(0, 0.9, 0)
		target.hit(DAMAGE)
	Fx.tracer(get_tree().root, _flash.global_position, end)
	return target


func tick(dt: float) -> void:
	_fire_t = maxf(0.0, _fire_t - dt)
	_flash.light_energy = maxf(0.0, _flash.light_energy - dt * 60.0)
	_flash.visible = _flash.light_energy > 0.0
	var b := global_transform.basis
	var dir := (-b.z * _move.y + b.x * _move.x)
	dir.y = 0
	velocity = dir * MOVE_SPEED
	move_and_slide()
	position.y = 0.0
	_kick = maxf(0.0, _kick - dt * 9.0)  # recoil springs back in about 0.1 s
	var bob := sin(Time.get_ticks_msec() * 0.012) * 0.012 * _move.length()
	_gun.position = gun_rest + Vector3(0, bob, 0.06 * _kick)
	_gun.rotation = Vector3(0.08 * _kick, 0.38, -0.05)  # angled so the side of the gun shows
