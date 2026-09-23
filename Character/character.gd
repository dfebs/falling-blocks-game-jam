extends CharacterBody2D
class_name DeliveryMan

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_SPEED = 50
var speed_modifier = 0
var _boost_timer = 0
var boost_dur = 1
@export var direction = -1
@export var ray_cast_2d: RayCast2D
@export var JUMP_VELOCITY = -250
var jump_bonus = 0
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
	var queue_jump = false
	var new_fx = false
	if is_on_floor():
		if velocity.y >= 0:
			velocity.y = 0
	else:
		velocity.y += gravity * delta
	
	velocity.x = direction * (MAX_SPEED + speed_modifier)
	if _boost_timer > 0:
		_boost_timer -= delta
	else:
		speed_modifier = 0
	if is_on_floor() and not ray_cast_2d.is_colliding() and is_on_flat_ground():
		queue_jump = true
	elif is_on_floor() and jump_detector.is_colliding() and not wall_detector.is_colliding():
		queue_jump = true
	
	move_and_slide()
	
	if is_on_floor() and get_slide_collision_count() > 0:
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		
		# Confirm we are actually hitting a wall side-on, not the floor beneath us
		if !queue_jump and abs(collision.get_normal().x) > 0.7:
			direction *= -1
			scale *= Vector2(-1, 1)
			audio_player.stream = sound_three
			audio_player.play()
			
		if collider is TileMapLayer:
			var new_tile = detect_tile_below_player(collider)
			check_new_tile_effects(new_tile)
			most_recent_tile = new_tile
			var head_tile = detect_tile_player_head(collider)
			var body_tile = detect_tile_bottom_half(collider)
			if head_tile and body_tile:
				die()
			elif body_tile:
				check_new_tile_effects(body_tile)
				
	if queue_jump and not new_fx:
		jump()


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
		return tile_data.get_custom_data("type")
	else:
		return ""

func check_new_tile_effects(tile_type) -> bool:
	var has_fx = true
	match(tile_type):
		"boost":
			jump_bonus = JUMP_VELOCITY
			mega_jump()
		"boost2":
			speed_modifier += MAX_SPEED
			_boost_timer = boost_dur
		"water":
			speed_modifier = -(MAX_SPEED / 2)
			_boost_timer = boost_dur
		_:
			has_fx = false
	return has_fx

func jump():
	audio_player.stream = sound_two
	audio_player.play()
	velocity.y = JUMP_VELOCITY + jump_bonus
	jump_bonus = 0
	
func mega_jump():
	audio_player.stream = sound_two
	audio_player.play()
	velocity.y = JUMP_VELOCITY + jump_bonus

func is_on_flat_ground() -> bool:
	var normal = get_floor_normal()
	return abs(normal.x) < 0.05

func die():
	audio_player.stream = sound_one
	audio_player.play()
	died.emit()
