extends Node2D
class_name BaseLevel

var _character_scene = "uid://o7f501dp7rbj"
var _character: DeliveryMan

signal level_complete_signal
signal level_failed_signal

func _ready():
	_character = load(_character_scene).instantiate()
	$Start.call_deferred("add_child", _character)
	_character.died.connect(level_failed)
	if !$Finish:
		push_error("Finish line missing")
	else:
		$Finish.area_2d.body_entered.connect(level_complete)

func level_complete(body):
	if body is DeliveryMan:
		print("done")
		body.freeze = true
		level_complete_signal.emit()

func level_failed():
	level_failed_signal.emit()
