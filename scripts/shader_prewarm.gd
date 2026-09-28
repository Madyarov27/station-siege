extends Node

@export var sweep_points: Array[Vector3] = [
	Vector3(60, 1.6, 12),
	Vector3(150, 1.6, -10),
	Vector3(190, 1.6, 10),
	Vector3(113, 1.6, -1),
	Vector3(119, 1.6, 17),
	Vector3(106, 1.6, 36),
	Vector3(129, 1.6, -2),
	Vector3(145, 1.6, -2),
	Vector3(106, 1.6, 47),
]
@export var frames_per_point := 3

func _ready():
	call_deferred("_run_prewarm")

func _run_prewarm():
	var player = get_tree().get_first_node_in_group("player")
	var overlay = get_node_or_null("/root/Node3D/LoadingOverlay")

	if player:
		player.set_physics_process(false)
		player.set_process(false)
		player.set_process_unhandled_input(false)

	if overlay:
		overlay.visible = true

	var cam = Camera3D.new()
	add_child(cam)
	cam.current = true

	for point in sweep_points:
		cam.global_position = point
		for i in frames_per_point:
			await get_tree().process_frame

	cam.queue_free()

	if overlay:
		overlay.visible = false

	if player:
		player.set_physics_process(true)
		player.set_process(true)
		player.set_process_unhandled_input(true)
		if player.has_node("Camera3D"):
			player.get_node("Camera3D").current = true
