extends CharacterBody2D
class_name DeliveryMan

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_SPEED = 50
@export var direction = -1
@export var ray_cast_2d: RayCast2D
@export var JUMP_VELOCITY = -250
@export var audio_player: AudioStreamPlayer2D
var sound_one = preload("res://Assets/Audio/fail.wav")
var sound_two = preload("res://Assets/Audio/spring.wav")
var sound_three = preload("res://Assets/Audio/thud.wav")
@export var remote_transform_2d: RemoteTransform2D
@export var jump_detector: RayCast2D
@export var wall_detector: RayCast2D

var most_recent_tile: String = ""

var freeze = false
signal died

func _physics_process(delta: float) -> void:
	if freeze: return
	if is_on_floor():
		if velocity.y >= 0:
			velocity.y = 0
	else:
		velocity.y += gravity * delta
	
	velocity.x = direction * MAX_SPEED
	if is_on_floor() and not ray_cast_2d.is_colliding() and is_on_flat_ground():
		jump()
	elif is_on_floor() and jump_detector.is_colliding() and not wall_detector.is_colliding():
		jump()
	
	move_and_slide()
	
	if is_on_floor() and get_slide_collision_count() > 0:
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		
		# Confirm we are actually hitting a wall side-on, not the floor beneath us
		if abs(collision.get_normal().x) > 0.7:
			direction *= -1
			scale *= Vector2(-1, 1)
			audio_player.stream = sound_three
			audio_player.play()
			
		if collider is TileMapLayer:
			var new_tile = detect_tile_below_player(collider)
			if most_recent_tile != new_tile:
				check_new_tile_effects(new_tile)
			most_recent_tile = new_tile
			var head_tile = detect_tile_player_head(collider)
			var body_tile = detect_tile_bottom_half(collider)
			if head_tile and body_tile:
				die()


func detect_tile_player_head(tilemap) -> String:
	var local = tilemap.to_local(global_position - Vector2(0, 12))
	return detect_tile_at_location(local, tilemap)

func detect_tile_bottom_half(tilemap) -> String:
	var local = tilemap.to_local(global_position - Vector2(0, -8))
	return detect_tile_at_location(local, tilemap)

func detect_tile_below_player(tilemap) -> String:
	var local = tilemap.to_local(global_position - Vector2(0, -24))
	return detect_tile_at_location(local, tilemap)

func detect_tile_at_location(pos, tilemap) -> String:
	var tile = tilemap.local_to_map(pos)
	var tile_data = tilemap.get_cell_tile_data(tile)
	if tile_data:
		var type = tile_data.get_custom_data("type")
		return type
	else:
		return ""

func check_new_tile_effects(tile_type):
	print(tile_type)

func jump():
		audio_player.stream = sound_two
		audio_player.play()
		velocity.y = JUMP_VELOCITY

func is_on_flat_ground() -> bool:
	var normal = get_floor_normal()
	return abs(normal.x) < 0.05

func die():
	audio_player.stream = sound_one
	audio_player.play()
	died.emit()
