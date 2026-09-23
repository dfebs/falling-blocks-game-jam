extends Node2D
class_name MainScript

@export var sprite_2d: Sprite2D
@export var start_button: Button
@export var victory_ui: Control
@export var start_menu: Control
@export var settings: Control
@export var camera_toggle: Button

@export var audio_player: AudioStreamPlayer2D
var main_track = preload("res://Assets/Audio/main_track.wav")
var menu_track = preload("res://Assets/Audio/menu_music.wav")
@export var camera_2d: Camera2D

var paused = false
var started = false
var dragging = false
@export var free_cam = true

static var _scenes_dict

var level_index = -1

var reload_held_counter = 0

var curr_level: BaseLevel

func _ready():
	if !start_button:
		push_error("Start button missing")
	start_button.pressed.connect(_start_pressed)
	settings.close_button_pressed.connect(toggle_settings_menu)

func _process(delta):
	if Input.is_action_pressed("Reload"):
		reload_held_counter += delta
		if reload_held_counter > 1:
			reload_current_level()
	elif Input.is_action_just_released("Reload"):
			reload_held_counter = 0
	else:
		reload_held_counter = 0

func _start_pressed():
	if settings.visible:
		return
	start_game()

func start_game():
	started = true
	if sprite_2d:
		sprite_2d.visible = false
	start_button.disabled = true
	start_button.visible = false
	start_menu.visible = false
	camera_toggle.visible = true
	settings.visible = false
	camera_2d.zoom = Vector2(0.5, 0.5)
	
	_scenes_dict = dir_contents('res://Levels/')
	next_level()
	
func reload_current_level():
	if !curr_level: return
	spawn_level()

func next_level():
	if level_index + 1 < len(_scenes_dict):
		level_index += 1
		spawn_level()
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

	scene_loads.sort_custom(func(a, b): return a.resource_path < b.resource_path)
	return scene_loads

func spawn_level():
	if curr_level:
		curr_level.queue_free()
	curr_level = _scenes_dict[level_index].instantiate()
	curr_level.level_complete_signal.connect(next_level)
	curr_level.level_failed_signal.connect(reload_current_level)
	call_deferred("add_child", curr_level)
	if !free_cam:
		curr_level.call_deferred("connect_camera", camera_2d)

func _unhandled_key_input(event):
	if event.is_action_pressed("Escape"):
		toggle_pause()
	if event.is_action_pressed("Mute"):
		audio_player.stream_paused = !audio_player.stream_paused
	if event.is_action_pressed("Toggle Camera"):
		_on_camera_toggle_pressed()

func toggle_settings_menu():
	settings.visible = !settings.visible
	paused = settings.visible
	get_tree().paused = paused

func toggle_pause():
	paused = !paused
	settings.visible = paused
	get_tree().paused = paused

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var zoom_pos:Vector2 = get_global_mouse_position()
				var zoom_scale:float = (event.factor if event.factor else 1.0) / 10
				zoom_at(zoom_pos, zoom_scale)

			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var zoom_pos:Vector2 = get_global_mouse_position()
				var zoom_scale:float = (event.factor if event.factor else 1.0) / 10
				zoom_at(zoom_pos, -zoom_scale)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		camera_2d.position -= event.relative / camera_2d.zoom

func zoom_at(pos, scale):
	if camera_2d.zoom.x + scale <= 0.01:
		scale = 0.01
	if camera_2d.zoom.x + scale >= 4:
		scale = 4
	camera_2d.zoom += Vector2(scale, scale)

func _on_button_pressed():
	if curr_level:
		curr_level.queue_free()
	started = false
	level_index = -1
	if sprite_2d:
		sprite_2d.visible = true
	start_button.disabled = false
	start_button.visible = true
	start_menu.visible = true
	camera_toggle.visible = false
	camera_2d.zoom = Vector2(0.5, 0.5)
	camera_2d.position = Vector2(0, 0)
	victory_ui.visible = false
	settings.visible = false
	

func _on_music_audio_stream_player_finished():
	if started:
		audio_player.stream = main_track
		audio_player.play()
	else:
		audio_player.stream = menu_track
		audio_player.play()

func _on_camera_toggle_pressed():
	free_cam = !free_cam
	if free_cam:
		curr_level.disconnect_camera()
	else:
		curr_level.call_deferred("connect_camera", camera_2d)

func _on_settings_button_pressed():
	if !settings.visible:
		settings.visible = true
