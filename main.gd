extends Node2D
class_name MainScript

@export var sprite_2d: Sprite2D
@export var start_button: Button
@export var victory_ui: Node2D
@export var ui: Control
@export var audio_player: AudioStreamPlayer2D
var main_track = preload("res://Assets/Audio/main_track.wav")
var menu_track = preload("res://Assets/Audio/menu_music.wav")

var paused = false
var started = false

static var _scenes_dict

var level_index = -1

var reload_held_counter = 0

var curr_level: BaseLevel

func _ready():
	if !start_button:
		push_error("Start button missing")
	start_button.pressed.connect(start_game)

func _process(delta):
	if Input.is_action_pressed("Reload"):
		reload_held_counter += delta
		if reload_held_counter > 1:
			reload_current_level()
	else:
		reload_held_counter = 0

func start_game():
	started = true
	if sprite_2d:
		sprite_2d.visible = false
	start_button.disabled = true
	start_button.visible = false
	
	_scenes_dict = dir_contents('res://Levels/')
	next_level()
	
func reload_current_level():
	curr_level.queue_free()
	curr_level = _scenes_dict[level_index].instantiate()
	curr_level.level_complete_signal.connect(next_level)
	call_deferred("add_child", curr_level)

func next_level():
	level_index += 1
	if level_index < len(_scenes_dict):
		if curr_level:
			curr_level.queue_free()
		curr_level = _scenes_dict[level_index].instantiate()
		curr_level.level_complete_signal.connect(next_level)
		call_deferred("add_child", curr_level)
	else:
		victory_ui.visible = true

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

func _unhandled_key_input(event):
	if event.is_action_pressed("Escape"):
		paused = !paused
		ui.visible = paused
		get_tree().paused = paused

func _on_button_pressed():
	get_tree().reload_current_scene()

func _on_music_audio_stream_player_finished():
	if started:
		audio_player.stream = main_track
		audio_player.play()
	else:
		audio_player.stream = menu_track
		audio_player.play()
