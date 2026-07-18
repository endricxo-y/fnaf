extends Reference
class_name LookDownDetector

var threshold := 0.8
var is_looking_down := false

func check(mouse_y: float, screen_h: float) -> bool:
    var looking = mouse_y > screen_h * threshold
    is_looking_down = looking
    return looking
