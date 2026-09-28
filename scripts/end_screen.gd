extends Control

func _ready():
	visible = false
	$ButtonsContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$ButtonsContainer/MenuButton.pressed.connect(_on_menu_pressed)

func show_screen(title_text: String, subtitle_text: String = ""):
	$Title.text = title_text
	$Subtitle.text = subtitle_text
	$Subtitle.visible = subtitle_text != ""
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
