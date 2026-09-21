extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$ButtonsContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$ButtonsContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$ButtonsContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	toggle_pause()
	
func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/node_3d.tscn")
