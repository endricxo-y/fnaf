extends Node
class_name DoorInputHandler

signal drag_started
signal drag_ended

export(float) var mouse_sensitivity := 0.008

var pulling := false
var drag_start_mouse_y := 0.0
var drag_start_door_y := 0.0

onready var area = get_parent().get_node("Area") if get_parent().has_node("Area") else null

func _ready() -> void:
    if area:
        area.input_ray_pickable = true
        area.connect("input_event", self, "_on_area_input")

func _on_area_input(_camera: Camera, event: InputEvent, _click_pos, _click_normal, _shape_idx) -> void:
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
        if event.pressed and not pulling:
            pulling = true
            drag_start_mouse_y = get_viewport().get_mouse_position().y
            drag_start_door_y = get_parent().translation.y
            emit_signal("drag_started")
        elif not event.pressed and pulling:
            pulling = false
            emit_signal("drag_ended")

func get_drag_target_y(closed_y: float, open_y: float, obstacle_top: float) -> float:
    var mouse_y = get_viewport().get_mouse_position().y
    var delta_y = (mouse_y - drag_start_mouse_y) * mouse_sensitivity
    var target_y = clamp(drag_start_door_y - delta_y, closed_y, open_y)
    if obstacle_top > -INF:
        var half_height = get_parent().scale.y * 0.5
        target_y = max(target_y, obstacle_top + half_height)
    return target_y

func is_mouse_still_down() -> bool:
    return Input.is_mouse_button_pressed(BUTTON_LEFT)
