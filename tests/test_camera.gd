## Camera rig: drive modes cycle without first person, chase offset, boost FOV, first-person head.
extends TestCase

var cam: CameraRig
var target: Node3D


func _setup() -> void:
	target = Node3D.new()
	tree.root.add_child(target)
	target.position = Vector3(2, 0, 100)
	cam = CameraRig.new()
	tree.root.add_child(cam)


func cleanup() -> void:
	for n in [cam, target]:
		if is_instance_valid(n):
			n.free()


func test_cycle_skips_first_person() -> void:
	_setup()
	var seen := []
	for i in 6:
		cam.cycle_drive_mode()
		seen.append(cam.mode)
	assert_true(not seen.has(CameraRig.Mode.FIRST_PERSON), "never first person")
	assert_true(seen.has(CameraRig.Mode.TOPDOWN) and seen.has(CameraRig.Mode.SIDE) and seen.has(CameraRig.Mode.CHASE), "all three drive views")


func test_chase_offset() -> void:
	_setup()
	for i in 120:
		cam.follow(target, 1.0 / 60.0)
	assert_true(cam.global_position.distance_to(target.position + Vector3(0, 7, -12.5)) < 0.1, "at %s" % cam.global_position)


func test_boost_widens_fov() -> void:
	_setup()
	for i in 120:
		cam.follow(target, 1.0 / 60.0, true)
	assert_true(cam.fov > 83.0, "fov %s" % cam.fov)


func test_first_person_sits_at_head() -> void:
	_setup()
	var head := Node3D.new()
	target.add_child(head)
	head.position = Vector3(0, 1.7, 0)
	cam.set_first_person(head)
	cam.follow(target, 1.0 / 60.0)
	assert_eq(cam.mode, CameraRig.Mode.FIRST_PERSON, "mode")
	assert_true(cam.global_position.distance_to(head.global_position) < 0.01, "at the head")
