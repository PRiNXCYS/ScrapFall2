## On foot: aim assist, loot, getting out of and back into the truck.
extends TestCase

var nodes: Array = []


func cleanup() -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.free()


func _b(pos: Vector3) -> SkitterBrain:
	var b := SkitterBrain.new()
	b.pos = pos
	return b


func test_aim_assist_picks_inside_cone() -> void:
	var ahead := _b(Vector3(1.0, 0, 20))  # about 3 degrees off
	var wide := _b(Vector3(15, 0, 15))  # 45 degrees off
	var got := AimAssist.pick(Vector3.ZERO, Vector3(0, 0, 1), [wide, ahead])
	assert_true(got == ahead, "picks the one inside 12 degrees")


func test_aim_assist_ignores_behind() -> void:
	assert_true(AimAssist.pick(Vector3.ZERO, Vector3(0, 0, 1), [_b(Vector3(0, 0, -10))]) == null, "nothing behind")


func test_loot_crate_gives_scrap() -> void:
	var site := StopSite.new()
	tree.root.add_child(site)
	nodes.append(site)
	var n0 := site.loot_left()
	assert_eq(n0, 3, "three crates")
	var crate: Vector3 = site.crate_positions()[0]
	assert_eq(site.loot_near(crate + Vector3(1, 0, 0)), 5, "5 scrap")
	assert_eq(site.loot_left(), 2, "crate used")
	assert_eq(site.loot_near(crate), 0, "empty now")


func test_enter_and_leave_truck() -> void:
	var drive := TruckDrive.new()
	var cam := CameraRig.new()
	var head := Node3D.new()
	tree.root.add_child(cam)
	tree.root.add_child(head)
	nodes.append_array([cam, head])
	StopRules.begin_stop(drive, cam, head)
	assert_true(drive.parked, "truck parked")
	assert_eq(cam.mode, CameraRig.Mode.FIRST_PERSON, "first person")
	assert_true(not StopRules.try_end_stop(drive, cam, Vector3(10, 0, 0), Vector3.ZERO), "too far from the truck")
	assert_true(StopRules.try_end_stop(drive, cam, Vector3(2.5, 0, 0), Vector3.ZERO), "next to the truck")
	assert_true(not drive.parked, "driving")
	assert_eq(cam.mode, CameraRig.Mode.CHASE, "back to the chase camera")


func test_camera_faces_where_you_shoot() -> void:
	var p := PlayerFP.new()
	tree.root.add_child(p)
	nodes.append(p)
	p.rotation.y = -PI / 2
	var cam_forward := -p.head.global_transform.basis.z
	assert_true(p.forward().is_equal_approx(cam_forward), "shooting direction = camera direction")
	assert_true(p.forward().x > 0.99, "rotation -PI/2 faces +x, got %s" % p.forward())
