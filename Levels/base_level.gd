extends Node2D
class_name BaseLevel

var _character_scene = "uid://o7f501dp7rbj"
var _character: DeliveryMan
@onready var grid: BlockGrid = $Grid

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
		body.freeze = true
		level_complete_signal.emit()

func level_failed():
	level_failed_signal.emit()

func connect_camera(camera: Node2D):
	_character.remote_transform_2d.remote_path = camera.get_path()

func disconnect_camera():
	_character.remote_transform_2d.remote_path = ""
