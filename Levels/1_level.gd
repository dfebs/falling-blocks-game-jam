extends BaseLevel

func _ready():
	var character = load(_character_scene).instantiate()
	start_marker.call_deferred("add_child", character)
	if !finish:
		push_error("Finish line missing")
	else:
		finish.area_2d.body_entered.connect(level_complete)
