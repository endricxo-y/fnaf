extends Spatial
class_name DoorObstacleDetector

func get_obstacle_top() -> float:
	var space_state = get_world().direct_space_state
	var door_pos = get_parent().global_transform.origin
	var ray_from = door_pos + Vector3(0, 20, 0)
	var ray_to = door_pos + Vector3(0, -20, 0)
	var result = space_state.intersect_ray(ray_from, ray_to, [], 0x7FFFFFFF, true, false)
	if result:
		return result.position.y
	return -INF
