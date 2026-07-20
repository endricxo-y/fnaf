extends Reference
class_name PlayerHide

enum State { VISIBLE, HIDING, HIDDEN }

export(String) var hiding_text := "HIDING..."
export(String) var hidden_text := "HIDDEN"

var state = State.VISIBLE
var progress := 0.0
var enter_duration := 0.4
var exit_duration := 0.25
var key_held := false
var near_spot := false

func process(delta, just_pressed, just_released, in_range):
	key_held = not just_released and (just_pressed or key_held)
	near_spot = in_range

	match state:
		State.VISIBLE:
			if key_held and near_spot:
				state = State.HIDING
				progress = 0.0

		State.HIDING:
			if not key_held or not near_spot:
				state = State.VISIBLE
				progress = 0.0
			else:
				progress = min(progress + delta / enter_duration, 1.0)
				if progress >= 1.0:
					state = State.HIDDEN

		State.HIDDEN:
			if not key_held or not near_spot:
				state = State.VISIBLE
				progress = 0.0

func get_hide_amount() -> float:
	match state:
		State.VISIBLE:
			return 0.0
		State.HIDING:
			return progress
		State.HIDDEN:
			return 1.0
		_:
			return 0.0

func is_hiding() -> bool:
	return state == State.HIDDEN

func is_transitioning() -> bool:
	return state == State.HIDING

func get_state_text() -> String:
	match state:
		State.VISIBLE:
			return ""
		State.HIDING:
			return hiding_text
		State.HIDDEN:
			return hidden_text
		_:
			return ""
