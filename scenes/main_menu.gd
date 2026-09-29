extends Control

const GAME_SCENE := "res://scenes/node_3d.tscn"
var loading := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$ButtonsContainer/StartButton.pressed.connect(_on_start_pressed)
	$ButtonsContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$ButtonsContainer/ControlsButton.pressed.connect(_show_controls.bind(true))
	$ControlsScreen/BackButton.pressed.connect(_show_controls.bind(false))
	# browsers don't allow a page to close itself, so Quit can't work on web
	if OS.has_feature("web"):
		$ButtonsContainer/QuitButton.visible = false


func _on_start_pressed():
	if loading:
		return
	loading = true
	$ButtonsContainer.visible = false
	$LoadingScreen.visible = true
	ResourceLoader.load_threaded_request(GAME_SCENE)

func _process(_delta):
	if not loading:
		return
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				$LoadingScreen/Label.text = "Loading... %d%%" % int(progress[0] * 100)
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(GAME_SCENE)
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			$LoadingScreen/Label.text = "Failed to load - please refresh the page."
			loading = false

func _show_controls(show: bool):
	$ControlsScreen.visible = show
	$ButtonsContainer.visible = not show
	$Title.visible = not show

func _on_quit_pressed():
	get_tree().quit()
