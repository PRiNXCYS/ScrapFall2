## One camera for every phase: chase / top-down / side while driving or camping, first person on foot.
class_name CameraRig
extends Camera3D

enum Mode { CHASE, TOPDOWN, SIDE, FIRST_PERSON }

const OFFSETS := {
	Mode.CHASE: [Vector3(0, 7, -12.5), Vector3(0, 1.5, 14)],
	Mode.TOPDOWN: [Vector3(-5, 24, -13), Vector3(0, 0, 6)],
	Mode.SIDE: [Vector3(13, 4, 9), Vector3(0, 2, 0)],
}

var mode := Mode.CHASE
var drive_mode := Mode.CHASE  # the view to return to after first person
var _head: Node3D
var _shake := 0.0
var _placed := false


func _ready() -> void:
	fov = 70.0


func cycle_drive_mode() -> void:
	drive_mode = {Mode.CHASE: Mode.TOPDOWN, Mode.TOPDOWN: Mode.SIDE, Mode.SIDE: Mode.CHASE}.get(drive_mode, Mode.CHASE)
	mode = drive_mode
	_head = null


func set_drive_mode(m: Mode) -> void:
	drive_mode = m
	mode = m
	_head = null


func set_first_person(head: Node3D) -> void:
	_head = head
	mode = Mode.FIRST_PERSON


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func follow(target: Node3D, dt: float, boosting := false) -> void:
	_shake = maxf(0.0, _shake - dt * 3.0)
	if mode == Mode.FIRST_PERSON and is_instance_valid(_head):
		global_transform = _head.global_transform
		fov = 75.0
		return
	var o: Array = OFFSETS[mode]
	var p := target.global_position
	var want: Vector3 = p + o[0]
	var k := 1.0 - exp(-5.0 * dt)
	global_position = global_position.lerp(want, k) if _placed else want
	global_position.z = want.z  # never lag along the road
	_placed = true
	var sh := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.4
	look_at(p + o[1] + sh, Vector3.UP)
	fov = lerpf(fov, 84.0 if boosting else 70.0, 1.0 - exp(-4.0 * dt))
