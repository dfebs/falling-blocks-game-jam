@tool
extends Sprite2D

func burn_away():
	var tween = create_tween()
	tween.tween_method(
		func(val: float): material.set_shader_parameter("progress", val),
		0.0, 1.0, 1.5 # From 0.0 to 1.0 over 1.5 seconds
	)

func _ready():
	burn_away()
