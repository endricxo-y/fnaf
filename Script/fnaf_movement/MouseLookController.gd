extends Reference
class_name MouseLookController

var yaw_offset := 0.0
var target_yaw_offset := 0.0

var max_yaw := 60.0
var min_yaw := -60.0
var deadzone_width := 150.0
var look_speed := 90.0
var smooth_speed := 10.0

func process_mouse(mouse_pos: Vector2, screen_center: Vector2, delta: float) -> void:
    var offset_x = mouse_pos.x - screen_center.x
    var move_x = 0.0

    if offset_x > deadzone_width:
        move_x = (offset_x - deadzone_width) / (screen_center.x - deadzone_width)
    elif offset_x < -deadzone_width:
        move_x = (offset_x + deadzone_width) / (screen_center.x - deadzone_width)

    move_x = clamp(move_x, -1.0, 1.0)
    target_yaw_offset -= move_x * look_speed * delta
    target_yaw_offset = clamp(target_yaw_offset, min_yaw, max_yaw)

    yaw_offset = lerp(yaw_offset, target_yaw_offset, smooth_speed * delta)

func reset() -> void:
    yaw_offset = 0.0
    target_yaw_offset = 0.0
