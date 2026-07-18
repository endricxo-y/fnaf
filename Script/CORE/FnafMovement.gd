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

var yaw_center := 0.0
var state = CameraState.State.FRONT
var front_pos := Vector3.ZERO

onready var camera: Spatial = $Camera if has_node("Camera") else self
onready var back_pos: Position3D = get_node(back_pos_path) if back_pos_path else null
onready var view_button: Button = get_node(view_button_path) if view_button_path else null

onready var mouse_look = MouseLookController.new()
onready var look_down = LookDownDetector.new()
onready var transitioner = ViewTransitioner.new()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	front_pos = camera.global_transform.origin
	if view_button:
		view_button.hide()

	mouse_look.max_yaw = max_yaw
	mouse_look.min_yaw = min_yaw
	mouse_look.deadzone_width = deadzone_width
	mouse_look.look_speed = look_speed
	mouse_look.smooth_speed = smooth_speed
	look_down.threshold = look_down_threshold
	transitioner.duration = move_duration

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

	camera.rotation_degrees.y = yaw_center + mouse_look.yaw_offset

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
