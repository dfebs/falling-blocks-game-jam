extends Node2D
class_name MainScript

@export var sprite_2d: Sprite2D
@export var start_button: Button

static var _scenes_dict

func _ready():
	if !start_button:
		push_error("Start button missing")
	start_button.pressed.connect(start_game)
	
	
func start_game():
	if sprite_2d:
		sprite_2d.visible = false
	start_button.disabled = true
	start_button.visible = false
	
	_scenes_dict = dir_contents('res://Levels/')
	var new_level = _scenes_dict[0].instantiate()
	add_child(new_level)

static func dir_contents(path):
	var scene_loads = []
		
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				if file_name.get_extension() == "tscn":
					var full_path = path.path_join(file_name)
					scene_loads.append(load(full_path))
				elif (".tscn" in file_name && file_name.get_extension() == "remap"):
					file_name = file_name.replace(".remap", "")
					var full_path = path.path_join(file_name)
					scene_loads.append(load(full_path))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

	return scene_loads
