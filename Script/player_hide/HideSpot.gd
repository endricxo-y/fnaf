extends Spatial
class_name HideSpot

export(float) var radius := 2.0

func _ready():
	add_to_group("hide_spots")
