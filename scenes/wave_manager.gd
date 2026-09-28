extends Node

@export var zombie_scenes: Array[PackedScene]
@export var spawn_points_root: NodePath
@export var starting_rooms: Array[String] = []
@export var max_rounds := 10
var current_round := 0
var zombies_alive := 0
var zombies_to_spawn := 0
var spawn_index := 0
var spawn_timer := 0.0
var spawn_interval := 4
var unlocked_rooms: Array[String] = []
var spawns_per_spawner := 2.0
var spawn_growth := 1.12
var spawn_queue: Array = []

func _ready():
	unlocked_rooms = starting_rooms.duplicate()
	start_next_round()
	
func unlock_room(room_name:String): 
	if room_name in unlocked_rooms:
		return
	unlocked_rooms.append(room_name)
	print("Room unlocked: ", room_name)	

	if spawn_queue.is_empty() and zombies_alive == 0 and current_round > 0:
		_refill_spawn_queue()
		
func _refill_spawn_queue():
	var active_points = _get_active_spawn_points()
	var per_spawner = int(round(spawns_per_spawner))
	spawn_queue.clear()
	for point in active_points:
		for i in per_spawner:
			spawn_queue.append(point)
			


func _get_active_spawn_points() -> Array:
	var root = get_node(spawn_points_root)
	var points := []
	print("currently unlocked ", unlocked_rooms)
	for room_name in unlocked_rooms:
		if root.has_node(room_name):
			var room_node = root.get_node(room_name)
			for child in room_node.get_children():
				points.append(child)
		else: 
			print("missing node", room_name)
	return points

func start_next_round():
	current_round += 1
	print("=== WAVE ", current_round, " ===")
	_refill_spawn_queue()
	spawn_timer = 0.0
	spawns_per_spawner *= spawn_growth
	display_wave_hud()
	$WaveSound.play()
	
func display_wave_hud():
	if not is_inside_tree():
		return
	var title = get_tree().get_first_node_in_group("wave_label")
	if title: 
		title.text = "Wave " + str(roundi(current_round))
		title.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_interval(4.0)
		tween.tween_property(title, "modulate:a", 0.0, 1.0)
	
	
		
func _process(delta):
	if spawn_queue.size() > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = spawn_interval
			var point = spawn_queue.pop_front()
			spawn_zombie_at(point)
			

func spawn_zombie_at(point) -> void:
	var chosen_scene = zombie_scenes[randi() % zombie_scenes.size()]
	var zombie = chosen_scene.instantiate()
	get_parent().add_child(zombie)
	zombie.global_position = point.global_position + Vector3(0, 1, 0)
	zombies_alive += 1
	print("Spawned zombie at ", zombie.global_position, " | alive now: ", zombies_alive)
	zombie.tree_exited.connect(_on_zombie_died)
	zombie.spawn_zombies()

func _on_zombie_died():
	zombies_alive -= 1
	print("A zombie left. alive now: ", zombies_alive)
	if zombies_alive <= 0 and spawn_queue.is_empty():
		if current_round >= max_rounds:
			print("you survived")
			win_game()
			return
		print("Round cleared!")
		await get_tree().create_timer(15.0).timeout
		start_next_round()
		
		
func win_game():
	var screen = get_tree().get_first_node_in_group("win_screen")
	if screen:
		screen.show_screen("VICTORY", "You survived all " + str(max_rounds) + " waves!")
	else:
		get_tree().paused = true
