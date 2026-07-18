extends Reference
class_name ViewTransitioner

var progress := 0.0
var duration := 3.5

var start_yaw_center := 0.0
var target_yaw_center := 0.0
var start_pos := Vector3.ZERO
var target_pos := Vector3.ZERO
var bob := 0.0

func start(from_yaw: float, to_yaw: float, from_pos: Vector3, to_pos: Vector3) -> void:
    progress = 0.0
    start_yaw_center = from_yaw
    target_yaw_center = to_yaw
    start_pos = from_pos
    target_pos = to_pos
    bob = 0.0

func update(delta: float) -> Dictionary:
    progress += delta / duration
    if progress >= 1.0:
        progress = 1.0
        return {
            "finished": true,
            "yaw": target_yaw_center,
            "position": target_pos
        }

    var t = Easing.smoothstep(progress)
    bob += delta * 10.0
    var pos = start_pos.linear_interpolate(target_pos, t)
    pos.y += sin(bob) * 0.025

    return {
        "finished": false,
        "yaw": lerp(start_yaw_center, target_yaw_center, t),
        "position": pos
    }
