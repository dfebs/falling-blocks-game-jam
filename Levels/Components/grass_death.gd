extends Control

@onready var sprite = $Sprite2D

func set_variation(variation: Vector2):
	sprite.texture.region = Rect2(variation.x, variation.y, 16, 16)
	sprite.burn_away()
