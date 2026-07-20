extends KinematicBody
class_name RobotCleaner

signal player_detected

export(NodePath) var waypoints_path
export(float) var detection_range := 4.5
export(float) var float_speed := 2.5
export(float) var float_amp := 0.12
export(float) var spin_speed := 25.0
export(float) var dwell_time := 30.0
export(bool) var debug_rays := true

enum State { PATROL, ATTACK, COOLDOWN }

var waypoints := []
var patrol_order := [0, 1, 3, 2]
var current_idx := 0
var state = State.PATROL
var dwell_timer := 0.0
var attack_timer := 0.0
var cooldown_timer := 0.0
var attack_trigger_wp := 2
var front_ray: RayCast
var left_ray: RayCast
var right_ray: RayCast
var debug_geo: ImmediateGeometry
var time := 0.0

onready var body_mesh: MeshInstance = $Body
onready var sweeper: MeshInstance = $Sweeper
onready var light_node: OmniLight = $Light
onready var player = get_node_or_null("../ClippedCamera")

func _ready():
	randomize()
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

	global_transform.origin = waypoints[patrol_order[0]]

	for idx in patrol_order:
		if idx < 0 or idx >= waypoints.size():
			set_process(false)
			return

	dwell_timer = dwell_time

func _setup_rays():
	var up = Vector3(0, 0.2, 0)
	front_ray = _make_ray(up + Vector3(0, 0, -0.5))
	left_ray = _make_ray(up + Vector3(-0.35, 0, -0.35))
	right_ray = _make_ray(up + Vector3(0.35, 0, -0.35))

func _make_ray(cast: Vector3) -> RayCast:
	var r = RayCast.new()
	r.cast_to = cast
	r.enabled = true
	r.exclude_parent = true
	add_child(r)
	return r

func _process(delta):
	time += delta
	match state:
		State.PATROL:
			_patrol(delta)
		State.ATTACK:
			_attack(delta)
		State.COOLDOWN:
			_cooldown(delta)
	_animate(delta)
	if debug_rays:
		_draw_debug_rays()

func _patrol(delta):
	if dwell_timer > 0:
		dwell_timer -= delta
		if light_node:
			light_node.light_color = Color(0.7, 0.85, 1.0)
			light_node.light_energy = 0.5 + sin(time * 2.5) * 0.15
		return

	if randf() < 0.5:
		dwell_timer = dwell_time
		return

	current_idx += 1
	if current_idx >= patrol_order.size():
		current_idx = 0

	global_transform.origin = waypoints[patrol_order[current_idx]]

	if patrol_order[current_idx] == attack_trigger_wp:
		state = State.ATTACK
		attack_timer = 2.0
		if light_node:
			light_node.light_color = Color(1, 0.2, 0.2)
		return

	dwell_timer = dwell_time

func _attack(delta):
	attack_timer -= delta

	if light_node:
		light_node.light_color = Color(1, 0.2, 0.2)
		light_node.light_energy = 0.5 + sin(time * 8.0) * 0.5

	if player and player.has_method("is_hiding") and player.is_hiding():
		_reset_attack()
		return

	if attack_timer <= 0 and _can_see_player():
		if light_node:
			light_node.light_color = Color(1, 1, 1)
			light_node.light_energy = 2.0
		emit_signal("player_detected")
		state = State.COOLDOWN
		cooldown_timer = 5.0
		current_idx = 0
		return

	if attack_timer <= 0:
		attack_timer = 2.0

func _can_see_player() -> bool:
	if not player:
		return false
	var from = global_transform.origin
	var to = player.global_transform.origin
	var dist = from.distance_to(to)
	if dist > detection_range:
		return false

	var space = get_world().direct_space_state
	var result = space.intersect_ray(from, to, [self])

	if result.empty():
		return true

	var hit_dist = from.distance_to(result.position)
	return hit_dist >= dist

func _reset_attack():
	state = State.COOLDOWN
	cooldown_timer = 3.0
	current_idx = 0
	if light_node:
		light_node.light_color = Color(0, 1, 0)
		light_node.light_energy = 1.0

func _cooldown(delta):
	cooldown_timer -= delta
	if light_node:
		light_node.light_energy = 0.3 + sin(time * 5.0) * 0.2
	if cooldown_timer <= 0:
		_reset_patrol()

func _reset_patrol():
	current_idx = 0
	global_transform.origin = waypoints[patrol_order[0]]
	dwell_timer = dwell_time
	state = State.PATROL
	if light_node:
		light_node.light_color = Color(0.7, 0.85, 1.0)

func _draw_debug_rays():
	debug_geo.clear()
	debug_geo.begin(Mesh.PRIMITIVE_LINES)
	_draw_line(front_ray, Color(0, 1, 0), Color(1, 0.5, 0))
	_draw_line(left_ray, Color(0.3, 0.8, 0), Color(1, 0.5, 0))
	_draw_line(right_ray, Color(0.3, 0.8, 0), Color(1, 0.5, 0))
	if player:
		var c = Color(1, 0, 0) if _can_see_player() else Color(1, 1, 0)
		debug_geo.set_color(c)
		debug_geo.add_vertex(Vector3.ZERO)
		debug_geo.add_vertex(to_local(player.global_transform.origin))
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
