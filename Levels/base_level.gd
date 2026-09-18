extends Node2D
class_name BaseLevel

var _character_scene = "uid://o7f501dp7rbj"
@export var start_marker: Marker2D
@export var finish: FinishLine

signal level_complete_signal

func level_complete(body):
	if body is DeliveryMan:
		print("done")
		body.freeze = true
		level_complete_signal.emit()
