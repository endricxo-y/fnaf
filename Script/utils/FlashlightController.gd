extends SpotLight
class_name FlashlightController

export(float, 0, 100) var light_range := 15.0
export(float, 0, 360) var light_angle := 50.0
export(float, 0, 10) var light_attenuation := 1.2
export(float, 0, 100) var light_brightness := 8.0
export(Color) var beam_color := Color(1, 1, 1)
export(bool) var cast_shadows := false
export(float, 0.1, 5.0) var ray_distance := 15.0
export(int, "key") var toggle_key := KEY_SHIFT

var _was_active := false
var _audio_player: AudioStreamPlayer

func _ready():
	visible = false
	translation = Vector3.ZERO
	light_energy = light_brightness
	light_color = beam_color
	light_bake_mode = 0
	spot_angle = light_angle
	spot_attenuation = light_attenuation
	spot_range = light_range
	shadow_enabled = cast_shadows

	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = preload("res://Asset/Sound/Flashlight.mp3")
	_audio_player.stream.loop = false
	add_child(_audio_player)

func _process(_delta):
	var active = Input.is_key_pressed(toggle_key)
	if active != _was_active:
		_play_sound()
	_was_active = active
	visible = active
	if not visible:
		return

	var camera = get_parent() as Camera
	if not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)
	look_at(from + dir * ray_distance, Vector3.UP)

func _play_sound():
	if _audio_player:
		_audio_player.stop()
		_audio_player.play()
