extends CharacterBody2D
class_name DeliveryMan

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_SPEED = 50
@export var direction = -1
@export var ray_cast_2d: RayCast2D
@export var JUMP_VELOCITY = -500
@export var audio_player: AudioStreamPlayer2D
var sound_one = preload("res://Assets/Audio/fail.wav")
var sound_two = preload("res://Assets/Audio/spring.wav")
var sound_three = preload("res://Assets/Audio/thud.wav")

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
		audio_player.stream = sound_two
		audio_player.play()
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()
	
	if is_on_floor() and get_slide_collision_count() > 0:
		var collision = get_last_slide_collision()
		var collider = collision.get_collider()
		
		# Confirm we are actually hitting a wall side-on, not the floor beneath us
		if !(collider is Floor) and abs(collision.get_normal().x) > 0.7:
			direction *= -1
			scale *= Vector2(-1, 1)
			audio_player.stream = sound_three
			audio_player.play()

func is_on_flat_ground() -> bool:
	var normal = get_floor_normal()
	return abs(normal.x) < 0.05

func die():
	audio_player.stream = sound_one
	audio_player.play()
	died.emit()
