extends Spatial

export(float) var closed_y := 0.0
export(float) var open_y := 3.67553
export(float) var spring_back_duration := 2.5
export(float) var auto_open_delay := 30.0
export(float) var full_close_threshold := 0.02
export(float) var cull_margin := 16.0

var state = DoorState.State.OPEN
var current_y := 0.0

onready var motion = DoorMotionController.new()
onready var input_handler
onready var obstacle

func _ready() -> void:
	current_y = open_y
	translation.y = current_y
	set("extra_cull_margin", cull_margin)
	for child in get_children():
		if child is CSGPrimitive:
			child.extra_cull_margin = cull_margin

	input_handler = DoorInputHandler.new()
	input_handler.name = "InputHandler"
	add_child(input_handler)

	obstacle = DoorObstacleDetector.new()
	obstacle.name = "ObstacleDetector"
	add_child(obstacle)

	input_handler.connect("drag_started", self, "_on_drag_started")
	input_handler.connect("drag_ended", self, "_end_drag")

	motion.open_y = open_y
	motion.closed_y = closed_y
	motion.spring_duration = spring_back_duration
	motion.auto_open_delay = auto_open_delay
	motion.full_close_threshold = full_close_threshold

func _on_drag_started() -> void:
	state = DoorState.State.PULLING

func _end_drag() -> void:
	input_handler.pulling = false
	if state == DoorState.State.PULLING:
		if DoorState.is_closed(current_y, closed_y, full_close_threshold):
			current_y = closed_y
			state = DoorState.State.CLOSED
			motion.reset_auto_open_timer()
		else:
			motion.start_spring_back(current_y)
			state = DoorState.State.SPRING_BACK

func _process(delta: float) -> void:
	match state:
		DoorState.State.PULLING:
			if not input_handler.is_mouse_still_down():
				_end_drag()
				return
			var obstacle_top = obstacle.get_obstacle_top()
			current_y = input_handler.get_drag_target_y(closed_y, open_y, obstacle_top)
			translation.y = current_y
			if DoorState.is_closed(current_y, closed_y, full_close_threshold):
				current_y = closed_y
				input_handler.pulling = false
				state = DoorState.State.CLOSED
				motion.reset_auto_open_timer()

		DoorState.State.SPRING_BACK:
			var result = motion.update_spring_back(delta)
			current_y = result["y"]
			translation.y = current_y
			if result["finished"]:
				state = DoorState.State.OPEN

		DoorState.State.CLOSED:
			if motion.update_auto_open_timer(delta):
				state = DoorState.State.AUTO_OPENING

		DoorState.State.AUTO_OPENING:
			var result = motion.update_auto_opening(delta, current_y)
			current_y = result["y"]
			translation.y = current_y
			if result["finished"]:
				state = DoorState.State.OPEN

	current_y = clamp(current_y, closed_y, open_y)
	translation.y = current_y
