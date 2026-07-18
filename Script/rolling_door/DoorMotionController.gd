extends Reference
class_name DoorMotionController

var spring_start_y := 0.0
var spring_timer := 0.0
var spring_duration := 2.5

var open_y := 3.67553
var closed_y := 0.0
var full_close_threshold := 0.02
var auto_open_delay := 30.0
var auto_open_speed := 0.4
var use_smooth_ease := true
var ease_smoothness := 2.0

var auto_open_timer := 0.0

func start_spring_back(from_y: float) -> void:
    spring_start_y = from_y
    spring_timer = 0.0

func update_spring_back(delta: float) -> Dictionary:
    spring_timer += delta
    var t = spring_timer / spring_duration
    if t >= 1.0:
        return {"finished": true, "y": open_y}
    t = Easing.smoothstep(t)
    return {"finished": false, "y": lerp(spring_start_y, open_y, t)}

func reset_auto_open_timer() -> void:
    auto_open_timer = 0.0

func update_auto_open_timer(delta: float) -> bool:
    auto_open_timer += delta
    return auto_open_timer >= auto_open_delay

func update_auto_opening(delta: float, current_y: float) -> Dictionary:
    var y = current_y
    if use_smooth_ease:
        y = lerp(current_y, open_y, ease_smoothness * delta)
        var finished = abs(open_y - y) < 0.03
        if finished:
            y = open_y
        return {"finished": finished, "y": y}
    y += auto_open_speed * delta
    var finished = y >= open_y
    if finished:
        y = open_y
    return {"finished": finished, "y": y}
