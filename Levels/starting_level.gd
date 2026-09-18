extends BaseLevel

func _ready():
	var scene = load(_character_scene)
	var character = scene.instantiate()
	start_marker.add_child(character)
