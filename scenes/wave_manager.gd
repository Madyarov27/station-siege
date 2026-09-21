extends Node

@export var zombie_scenes: Array[PackedScene]
@export var spawn_points_root: NodePath
@export var starting_rooms: Array[String] = []
@export var max_rounds := 30
var current_round := 0
var zombies_alive := 0
var zombies_to_spawn := 0
var spawn_index := 0
var spawn_timer := 0.0
var spawn_interval := 4
var unlocked_rooms: Array[String] = []


func _ready():
	unlocked_rooms = starting_rooms.duplicate()
	start_next_round()
	
func unlock_room(room_name:String): 
	if room_name in unlocked_rooms:
		return
	unlocked_rooms.append(room_name)
	print("Room unlocked: ", room_name)	

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
	print("=== ROUND ", current_round, " ===")
	# more zombies each round
	zombies_to_spawn = int(3 * pow(1.15, current_round))
	spawn_timer = 0.0
	display_wave_hud()
	$WaveSound.play()
	
func display_wave_hud():
	if not is_inside_tree():
		return
	var title = get_tree().get_first_node_in_group("wave_label")
	if title: 
		title.text = "Round " + str(roundi(current_round))
		title.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_interval(4.0)
		tween.tween_property(title, "modulate:a", 0.0, 1.0)
	
	
		
func _process(delta):
	if zombies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = spawn_interval
			if spawn_zombie():
				zombies_to_spawn -= 1
			

func spawn_zombie() -> bool:
	var spawn_points = _get_active_spawn_points()
	if spawn_points.is_empty():
		print("NO ACTIVE SPAWN POINTS FOUND")
		return false
	# cycle through points so zombies don't stack
	var point = spawn_points[spawn_index % spawn_points.size()]
	spawn_index += 1
	var chosen_scene = zombie_scenes[randi() % zombie_scenes.size()]
	var zombie = chosen_scene.instantiate()
	get_parent().add_child(zombie)
	zombie.global_position = point.global_position + Vector3(0, 1, 0)  # lift up a bit
	zombies_alive += 1
	print("Spawned zombie at ", zombie.global_position, " | alive now: ", zombies_alive)
	zombie.tree_exited.connect(_on_zombie_died)
	zombie.spawn_zombies()
	return true
func _on_zombie_died():
	zombies_alive -= 1
	print("A zombie left. alive now: ", zombies_alive)
	if zombies_alive <= 0 and zombies_to_spawn <= 0:
		if current_round >= max_rounds:
			print("you survived")
			win_game()
			return
		print("Round cleared!")
		await get_tree().create_timer(15.0).timeout
		start_next_round()
		
		
func win_game():
	get_tree().paused = true
	var win_label = get_tree().get_first_node_in_group("win_label")
	if win_label:
		win_label.visible = true
		win_label.text = "YOU SURVIVED"
