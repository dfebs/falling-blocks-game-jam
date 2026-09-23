extends Control

signal close_button_pressed

func _on_close_button_pressed():
	visible = false
	close_button_pressed.emit()
