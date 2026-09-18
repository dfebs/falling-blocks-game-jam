extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var MAX_SPEED = 2
@export var direction = 1

var bounce_cd = 1
var _cd_timer = 0

func _physics_process(delta: float) -> void:
	_cd_timer += delta
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = direction * MAX_SPEED
		move_toward(velocity.x, 0, MAX_SPEED)
	
	var collision = move_and_collide(velocity)
	if collision:
		var collider = collision.get_collider()
		if !(collider is Floor):
			#print("Collided with: ", collider.name)
			direction *= -1
		else:
			move_and_slide()
