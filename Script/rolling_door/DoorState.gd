extends Reference
class_name DoorState

enum State { OPEN, PULLING, SPRING_BACK, CLOSED, AUTO_OPENING }

static func is_closed(current_y: float, closed_y: float, threshold: float) -> bool:
    return abs(current_y - closed_y) <= threshold
