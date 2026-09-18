extends BaseLevel

func _ready():
	var character = load(_character_scene).instantiate()
	start_marker.add_child(character)
