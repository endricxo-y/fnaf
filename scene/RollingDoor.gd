extends Spatial

enum State { OPEN, PULLING, SPRING_BACK, CLOSED, AUTO_OPENING }

export var closed_y = 0.0
export var open_y = 3.67553

export var spring_back_duration = 2.5
export var auto_open_delay = 30.0

export var use_smooth_ease = true
export var ease_smoothness = 2.0
export var auto_open_speed = 0.4

export var full_close_threshold = 0.02
export var cull_margin = 16.0
export var mouse_sensitivity = 0.008

export(NodePath) var interaction_area
export(NodePath) var bottom_ray

var state = State.OPEN
var current_y = 0.0
var auto_open_timer = 0.0

var pulling = false
var drag_start_mouse_y = 0.0
var drag_start_door_y = 0.0

var spring_start_y = 0.0
var spring_timer = 0.0

onready var _area = get_node(interaction_area) if interaction_area else $Area
onready var _ray = get_node(bottom_ray) if bottom_ray else $BottomRay


func _ready():
	current_y = open_y
	translation.y = current_y

	set("extra_cull_margin", cull_margin)

	for child in get_children():
		if child is CSGPrimitive:
			child.extra_cull_margin = cull_margin

	if _area:
		_area.input_ray_pickable = true
		_area.connect("input_event", self, "_on_area_input")


func _on_area_input(_camera, event, _click_pos, _click_normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed and (state == State.OPEN or state == State.SPRING_BACK or state == State.CLOSED):
			pulling = true
			drag_start_mouse_y = get_viewport().get_mouse_position().y
			drag_start_door_y = translation.y
			state = State.PULLING
		elif not event.pressed and pulling:
			pulling = false
			_stop_pull()


func _stop_pull():
	if state == State.PULLING:
		if abs(current_y - closed_y) <= full_close_threshold:
			current_y = closed_y
			state = State.CLOSED
			auto_open_timer = 0.0
		else:
			spring_start_y = current_y
			spring_timer = 0.0
			state = State.SPRING_BACK


func _get_obstacle_top() -> float:
	var space_state = get_world().direct_space_state
	var door_pos = global_transform.origin
	var ray_from = door_pos + Vector3(0, 20, 0)
	var ray_to = door_pos + Vector3(0, -20, 0)
	var result = space_state.intersect_ray(ray_from, ray_to, [], 0x7FFFFFFF, true, false)
	if result:
		return result.position.y
	return -INF


func _process(delta):
	match state:
		State.PULLING:
			if not Input.is_mouse_button_pressed(BUTTON_LEFT):
				pulling = false
				_stop_pull()
				return

			var mouse_y = get_viewport().get_mouse_position().y
			var delta_y = (mouse_y - drag_start_mouse_y) * mouse_sensitivity
			var target_y = clamp(drag_start_door_y - delta_y, closed_y, open_y)

			var obstacle_top = _get_obstacle_top()
			if obstacle_top > -INF:
				var half_height = scale.y * 0.5
				target_y = max(target_y, obstacle_top + half_height)

			current_y = target_y
			translation.y = current_y

			if current_y <= closed_y + full_close_threshold:
				current_y = closed_y
				state = State.CLOSED
				auto_open_timer = 0.0

		State.SPRING_BACK:
			spring_timer += delta
			var t = spring_timer / spring_back_duration
			if t >= 1.0:
				current_y = open_y
				state = State.OPEN
			else:
				t = t * t * (3.0 - 2.0 * t)
				current_y = lerp(spring_start_y, open_y, t)
			translation.y = current_y

		State.CLOSED:
			auto_open_timer += delta
			if auto_open_timer >= auto_open_delay:
				state = State.AUTO_OPENING

		State.AUTO_OPENING:
			if use_smooth_ease:
				current_y = lerp(current_y, open_y, ease_smoothness * delta)
				if abs(open_y - current_y) < 0.03:
					current_y = open_y
					state = State.OPEN
			else:
				current_y += auto_open_speed * delta
				if current_y >= open_y:
					current_y = open_y
					state = State.OPEN
			translation.y = current_y

	current_y = clamp(current_y, closed_y, open_y)
	translation.y = current_y
