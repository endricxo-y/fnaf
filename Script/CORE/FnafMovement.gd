extends Spatial

export(float) var max_yaw := 60.0
export(float) var min_yaw := -60.0
export(float) var deadzone_width := 150.0
export(float) var look_speed := 90.0
export(float) var smooth_speed := 10.0
export(float) var look_down_threshold := 0.8
export(float) var move_duration := 3.5
export(NodePath) var back_pos_path
export(NodePath) var view_button_path
export(float) var hide_camera_offset := -0.8
export(String) var hide_prompt_text := "Press E to Hide"

var yaw_center := 0.0
var state = CameraState.State.FRONT
var front_pos := Vector3.ZERO
var e_held := false
var front_y := 0.0
var back_y := 0.0

onready var camera: Spatial = $Camera if has_node("Camera") else self
onready var back_pos: Position3D = get_node(back_pos_path) if back_pos_path else null
onready var view_button: Button = get_node(view_button_path) if view_button_path else null

onready var mouse_look = MouseLookController.new()
onready var look_down = LookDownDetector.new()
onready var transitioner = ViewTransitioner.new()
var hide_control = null

onready var walk_audio: AudioStreamPlayer = $WalkAudio if has_node("WalkAudio") else null

func _ready() -> void:
	hide_control = preload("res://Script/player_hide/PlayerHide.gd").new()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	front_pos = camera.global_transform.origin
	front_y = front_pos.y
	if back_pos:
		back_y = back_pos.global_transform.origin.y
	else:
		back_y = front_y
	if view_button:
		view_button.hide()

	mouse_look.max_yaw = max_yaw
	mouse_look.min_yaw = min_yaw
	mouse_look.deadzone_width = deadzone_width
	mouse_look.look_speed = look_speed
	mouse_look.smooth_speed = smooth_speed
	look_down.threshold = look_down_threshold
	transitioner.duration = move_duration

	var prompt = get_node_or_null("../HideUI/HidePrompt")
	var status = get_node_or_null("../HideUI/HideStatus")
	if prompt:
		prompt.add_color_override("font_color", Color(1, 1, 1))
	if status:
		status.add_color_override("font_color", Color(1, 1, 0))

func _process(delta: float) -> void:
	var screen = get_viewport().size
	var mouse_pos = get_viewport().get_mouse_position()

	var was_looking_down = look_down.is_looking_down
	var looking_down = look_down.check(mouse_pos.y, screen.y)
	if looking_down != was_looking_down and view_button:
		if looking_down and (state == CameraState.State.FRONT or state == CameraState.State.BACK):
			view_button.show()
		else:
			view_button.hide()

	var currently_held = Input.is_key_pressed(KEY_E)
	var just_pressed = currently_held and not e_held
	var just_released = not currently_held and e_held
	e_held = currently_held

	var in_range = _check_hide_spots()
	hide_control.process(delta, just_pressed, just_released, in_range)
	_update_hide_ui(in_range)
	_update_hide_camera(delta)

	match state:
		CameraState.State.FRONT, CameraState.State.BACK:
			mouse_look.process_mouse(mouse_pos, screen / 2.0, delta)
		CameraState.State.MOVING_TO_BACK, CameraState.State.MOVING_TO_FRONT:
			var result = transitioner.update(delta)
			camera.global_transform.origin = result["position"]
			yaw_center = result["yaw"]
			if result["finished"]:
				state = CameraState.State.BACK if transitioner.target_yaw_center > transitioner.start_yaw_center else CameraState.State.FRONT
				camera.global_transform.origin = transitioner.target_pos
				camera.rotation_degrees.y = yaw_center
				if view_button:
					view_button.disabled = false
					view_button.text = "FRONT" if state == CameraState.State.BACK else "BEHIND"
				if walk_audio:
					walk_audio.stop()

	camera.rotation_degrees.y = yaw_center + mouse_look.yaw_offset

func _check_hide_spots() -> bool:
	var spots = get_tree().get_nodes_in_group("hide_spots")
	var player_pos = camera.global_transform.origin
	for spot in spots:
		var r = 2.0
		if spot.get("radius") != null:
			r = spot.get("radius")
		if spot.global_transform.origin.distance_to(player_pos) < r:
			return true
	return false

func _update_hide_ui(in_range):
	var prompt = get_node_or_null("../HideUI/HidePrompt")
	var status = get_node_or_null("../HideUI/HideStatus")
	if not prompt or not status:
		return

	var hiding = hide_control.is_hiding()
	var transitioning = hide_control.is_transitioning()

	if hiding or transitioning:
		prompt.text = ""
		status.text = hide_control.get_state_text()
	elif in_range:
		prompt.text = hide_prompt_text
		status.text = ""
	else:
		prompt.text = ""
		status.text = ""

func _update_hide_camera(delta):
	if state == CameraState.State.FRONT or state == CameraState.State.BACK:
		var base = front_y if state == CameraState.State.FRONT else back_y
		var target_y = base + hide_camera_offset * hide_control.get_hide_amount()
		var pos = camera.global_transform.origin
		pos.y = lerp(pos.y, target_y, delta * 8.0)
		camera.global_transform.origin = pos

func is_hiding() -> bool:
	return hide_control.is_hiding()

func _on_view_button_pressed() -> void:
	match state:
		CameraState.State.FRONT:
			_start_move_to(CameraState.State.MOVING_TO_BACK, 180.0)
		CameraState.State.BACK:
			_start_move_to(CameraState.State.MOVING_TO_FRONT, -180.0)

func _start_move_to(target_state: int, yaw_delta: float) -> void:
	state = target_state
	transitioner.start(
		yaw_center,
		yaw_center + yaw_delta,
		camera.global_transform.origin,
		back_pos.global_transform.origin if yaw_delta > 0 else front_pos
	)
	mouse_look.reset()
	if view_button:
		view_button.hide()
		view_button.disabled = true
	if walk_audio:
		walk_audio.play()
