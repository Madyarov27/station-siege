extends Control

func _ready():
	visible = false

func show_note(text: String):
	$TextLabel.text = text
	visible = true

func hide_note():
	visible = false
