extends KinematicBody
class_name RobotCleaner

signal player_detected

export(NodePath) var waypoints_path
export(float) var patrol_duration := 60.0
export(float) var detection_range := 4.5
export(float) var float_speed := 2.5
export(float) var float_amp := 0.12
export(float) var spin_speed := 25.0
export(float) var move_speed := 2.5
export(float) var avoid_dist := 1.5
export(bool) var debug_rays := true

var waypoints := []
var target_idx := 0
var travel := 0.0
var time := 0.0
var player_visible := false
var forward := true
var on_cooldown := false
var cooldown_timer := 0.0
var velocity := Vector3.ZERO
var front_ray: RayCast
var left_ray: RayCast
var right_ray: RayCast
var detect_ray: RayCast
var debug_geo: ImmediateGeometry

onready var body_mesh: MeshInstance = $Body
onready var sweeper: MeshInstance = $Sweeper
onready var light_node: OmniLight = $Light
onready var player = get_node("../ClippedCamera")

func _ready():
	_setup_rays()
	if debug_rays:
		debug_geo = ImmediateGeometry.new()
		add_child(debug_geo)
	if waypoints_path:
		var container = get_node(waypoints_path)
		for child in container.get_children():
			if child is Position3D:
				waypoints.append(child.global_transform.origin)

	if waypoints.size() < 2:
		set_process(false)
		return

	global_transform.origin = waypoints[0]

func _setup_rays():
	var up = Vector3(0, 0.2, 0)
	front_ray = _make_ray(up + Vector3(0, 0, -avoid_dist))
	left_ray = _make_ray(up + Vector3(-avoid_dist * 0.7, 0, -avoid_dist * 0.7))
	right_ray = _make_ray(up + Vector3(avoid_dist * 0.7, 0, -avoid_dist * 0.7))
	detect_ray = _make_ray(Vector3(0, 0, -detection_range))

func _make_ray(cast: Vector3) -> RayCast:
	var r = RayCast.new()
	r.cast_to = cast
	r.enabled = true
	r.exclude_parent = true
	add_child(r)
	return r

func _process(delta):
	time += delta
	_patrol(delta)
	_animate(delta)
	_check_detection()
	if debug_rays:
		_draw_debug_rays()

func _patrol(delta):
	if on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			on_cooldown = false
			forward = false
			travel = 0.0
		return

	var seg_count = waypoints.size() - 1
	var seg_dur = patrol_duration / seg_count
	travel += delta / seg_dur

	if travel >= 1.0:
		travel = 0.0
		if forward:
			target_idx += 1
			if target_idx >= seg_count:
				on_cooldown = true
				cooldown_timer = 60.0
		else:
			target_idx -= 1
			if target_idx <= 0:
				forward = true

	var from = waypoints[target_idx]
	var to = waypoints[target_idx + 1] if forward else waypoints[target_idx - 1]
	var t = Easing.smoothstep(travel)
	var target_pos = from.linear_interpolate(to, t)

	var ideal_dir = (target_pos - global_transform.origin).normalized()
	ideal_dir.y = 0

	var avoid = Vector3.ZERO
	if front_ray.is_colliding():
		if not left_ray.is_colliding():
			avoid = -global_transform.basis.x * move_speed
		elif not right_ray.is_colliding():
			avoid = global_transform.basis.x * move_speed
		else:
			avoid = -global_transform.basis.z * move_speed * 0.5

	velocity.y -= 9.8 * delta

	var move_dir = ideal_dir * move_speed + avoid
	if move_dir.length() > 0.01:
		velocity.x = move_dir.normalized().x * move_speed
		velocity.z = move_dir.normalized().z * move_speed
	else:
		velocity.x = 0
		velocity.z = 0

	velocity = move_and_slide(velocity, Vector3.UP)

	if velocity.length() > 0.01:
		var angle = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, angle, delta * 3.0)

func _draw_debug_rays():
	debug_geo.clear()
	debug_geo.begin(Mesh.PRIMITIVE_LINES)

	_draw_line(front_ray, Color(0, 1, 0), Color(1, 0.5, 0))
	_draw_line(left_ray, Color(0.3, 0.8, 0), Color(1, 0.5, 0))
	_draw_line(right_ray, Color(0.3, 0.8, 0), Color(1, 0.5, 0))
	_draw_line(detect_ray, Color(1, 0, 0), Color(1, 1, 0))

	debug_geo.end()

func _draw_line(ray: RayCast, idle: Color, hit: Color):
	var c = hit if ray.is_colliding() else idle
	var end = ray.cast_to
	debug_geo.set_color(c)
	debug_geo.add_vertex(Vector3.ZERO)
	debug_geo.add_vertex(end)

func _animate(delta):
	body_mesh.translation.y = sin(time * float_speed) * float_amp
	sweeper.rotation.y += delta * deg2rad(spin_speed)

	if light_node:
		light_node.light_energy = 0.8 + sin(time * 2.5) * 0.1

func _check_detection():
	if not player:
		return

	var dir = player.global_transform.origin - global_transform.origin
	var dist = dir.length()
	var was_visible = player_visible

	detect_ray.cast_to = to_local(player.global_transform.origin)
	detect_ray.force_raycast_update()

	var can_see = true
	if detect_ray.is_colliding():
		var hit_local = to_local(detect_ray.get_collision_point())
		if hit_local.length() < dist:
			can_see = false

	player_visible = can_see and dist < detection_range

	if player_visible:
		var hiding = player.has_method("is_hiding") and player.is_hiding()
		if not hiding:
			if light_node:
				light_node.light_color = Color(1, 0.2, 0.2)
			if not was_visible:
				emit_signal("player_detected")
		else:
			if light_node:
				light_node.light_color = Color(1, 0.9, 0.3)
	else:
		if was_visible and light_node:
			light_node.light_color = Color(0.7, 0.85, 1.0)
