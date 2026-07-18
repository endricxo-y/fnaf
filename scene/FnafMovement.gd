extends Spatial

enum ViewState { FRONT, MOVING_TO_BACK, BACK, MOVING_TO_FRONT }

export var max_yaw = 60.0
export var min_yaw = -60.0
export var deadzone_width = 150.0
export var look_speed = 90.0
export var smooth_speed = 10.0

export var look_down_threshold = 0.8
export var move_duration = 3.5
export(NodePath) var back_pos_path
export(NodePath) var view_button_path

var yaw_offset = 0.0
var target_yaw_offset = 0.0
var yaw_center = 0.0

var view_state = ViewState.FRONT
var move_progress = 0.0
var move_start_yaw_center = 0.0
var move_target_yaw_center = 0.0
var move_start_pos := Vector3.ZERO
var move_target_pos := Vector3.ZERO

var walk_bob = 0.0
var is_looking_down = false
var front_pos := Vector3.ZERO

onready var camera = $Camera if has_node("Camera") else self
onready var back_pos = get_node(back_pos_path) if back_pos_path else null
onready var view_button = get_node(view_button_path) if view_button_path else null


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	front_pos = camera.global_transform.origin
	if view_button:
		view_button.hide()


func _process(delta):
	_check_look_down()

	match view_state:
		ViewState.FRONT, ViewState.BACK:
			_mouse_look(delta)
		ViewState.MOVING_TO_BACK, ViewState.MOVING_TO_FRONT:
			_update_movement(delta)

	camera.rotation_degrees.y = yaw_center + yaw_offset


func _check_look_down():
	var mouse_y = get_viewport().get_mouse_position().y
	var screen_h = get_viewport().size.y
	var looking = mouse_y > screen_h * look_down_threshold

	if looking != is_looking_down:
		is_looking_down = looking
		if view_button:
			if looking and (view_state == ViewState.FRONT or view_state == ViewState.BACK):
				view_button.show()
			else:
				view_button.hide()


func _mouse_look(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().size
	var center = screen_size / 2.0
	var offset_x = mouse_pos.x - center.x
	var move_x = 0.0

	if offset_x > deadzone_width:
		move_x = (offset_x - deadzone_width) / (center.x - deadzone_width)
	elif offset_x < -deadzone_width:
		move_x = (offset_x + deadzone_width) / (center.x - deadzone_width)

	move_x = clamp(move_x, -1.0, 1.0)
	target_yaw_offset -= move_x * look_speed * delta
	target_yaw_offset = clamp(target_yaw_offset, min_yaw, max_yaw)

	yaw_offset = lerp(yaw_offset, target_yaw_offset, smooth_speed * delta)


func _on_view_button_pressed():
	match view_state:
		ViewState.FRONT:
			_start_move_to(ViewState.MOVING_TO_BACK, 180.0)
		ViewState.BACK:
			_start_move_to(ViewState.MOVING_TO_FRONT, -180.0)


func _start_move_to(new_state, yaw_delta):
	view_state = new_state
	move_progress = 0.0
	move_start_yaw_center = yaw_center
	move_target_yaw_center = yaw_center + yaw_delta
	move_start_pos = camera.global_transform.origin
	move_target_pos = back_pos.global_transform.origin if yaw_delta > 0 else front_pos

	yaw_offset = 0.0
	target_yaw_offset = 0.0
	walk_bob = 0.0

	if view_button:
		view_button.hide()
		view_button.disabled = true


func _update_movement(delta):
	move_progress += delta / move_duration

	if move_progress >= 1.0:
		move_progress = 1.0
		view_state = ViewState.BACK if move_target_yaw_center > move_start_yaw_center else ViewState.FRONT
		yaw_center = move_target_yaw_center
		camera.global_transform.origin = move_target_pos
		camera.rotation_degrees.y = yaw_center

		if view_button:
			view_button.disabled = false
			view_button.text = "FRONT" if view_state == ViewState.BACK else "BEHIND"
		return

	var t = move_progress * move_progress * (3.0 - 2.0 * move_progress)
	yaw_center = lerp(move_start_yaw_center, move_target_yaw_center, t)
	camera.global_transform.origin = move_start_pos.linear_interpolate(move_target_pos, t)

	walk_bob += delta * 10.0
	camera.global_transform.origin.y += sin(walk_bob) * 0.025
	camera.rotation_degrees.y = yaw_center
