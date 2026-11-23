## Getting out of the truck at a stop, and back in.
class_name StopRules
extends RefCounted

const BOARD_DIST := 3.0  # how close to the truck you must be to drive on


static func begin_stop(drive: TruckDrive, cam: CameraRig, head: Node3D) -> void:
	drive.parked = true
	cam.set_first_person(head)


static func try_end_stop(drive: TruckDrive, cam: CameraRig, player_pos: Vector3, truck_pos: Vector3) -> bool:
	var a := Vector3(player_pos.x, 0, player_pos.z)
	var b := Vector3(truck_pos.x, 0, truck_pos.z)
	if a.distance_to(b) > BOARD_DIST:
		return false
	drive.parked = false
	cam.set_drive_mode(cam.drive_mode)
	return true
