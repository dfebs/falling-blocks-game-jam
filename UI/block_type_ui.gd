extends Sprite2D
class_name BlockTypeUI

@onready var label: Label = $Label
@onready var hotkey: Label = $Hotkey

var text = "":
	set(new_text):
		text = new_text
		if label:
			label.text = text

func _ready():
	label.text = text
