extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$ButtonsContainer/StartButton.pressed.connect(_on_start_pressed)
	$ButtonsContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/node_3d.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
