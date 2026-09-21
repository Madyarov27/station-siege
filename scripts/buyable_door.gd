extends Node3D

@export var price := 500
@export var slide_distance := 2.2
@export var slide_time := 1.0
@export var unlock_delay := 0.35

var unlocked := false
var is_opening := false

@onready var door: Node3D = get_node_or_null("door")


func _ready() -> void:
	add_to_group("doors")


func vanish(player) -> void:
	if unlocked or is_opening or door == null:
		return

	if player.gold < price:
		print("Need ", price - player.gold, " more")
		play_sound("DeniedSound")
		return

	player.gold -= price
	player.update_gold_display()
	open()


func open() -> void:
	is_opening = true

	play_sound("UnlockSound")
	await get_tree().create_timer(unlock_delay).timeout

	disable_shapes(door)
	drop_nav_obstacle()
	play_sound("OpenSound")

	var target: Vector3 = door.position + Vector3.RIGHT * slide_distance

	var tween := create_tween()
	tween.tween_property(door, "position", target, slide_time) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	await tween.finished
	unlocked = true
	is_opening = false


func disable_shapes(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
		disable_shapes(child)


func drop_nav_obstacle() -> void:
	for child in get_children():
		if child is NavigationObstacle3D:
			child.set_deferred("avoidance_enabled", false)
			child.set_deferred("affect_navigation_mesh", false)


func play_sound(sound_name: String) -> void:
	var node := get_node_or_null(sound_name)
	if node is AudioStreamPlayer3D:
		node.play()
