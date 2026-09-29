extends CharacterBody3D

var health := 100
var speed := 4
var attack_range := 1
var attack_damage := 10
var attack_cooldown := 1.0
var time_since_attack := 0.0
var is_spawning := false
var stuck_timer := 0.0
var escape_cooldown := 0.0
var unstuck_dir := Vector3.ZERO
var check_window_timer := 0.0
var window_start_position := Vector3.ZERO
var window_started := false
const PROGRESS_WINDOW := 5.0
const MIN_PROGRESS := 2.0
const MAX_NO_PROGRESS_WINDOWS := 4
var progress_timer := 0.0
var progress_origin := Vector3.INF
var no_progress_windows := 0




@onready var zombie_run = $"zombie/AnimationPlayer"
@onready var zombie_attack = $"zombie/AnimationPlayer2"
@onready var zombie_death = $"zombie/AnimationPlayer3"
@export var groan_sound: AudioStream
#@onready var zombie_crawl = $"Zombie Run (1)/AnimationPlayer4"
#@onready var zombie_standup = $"Zombie Run (1)/AnimationPlayer5"


func _ready():
	$GroanSound.stream = groan_sound
	$GroanTimer.timeout.connect(_on_groan_timer)
	start_groan_timer()
	# small tolerance so zombies reach each corner waypoint before turning,
	# instead of cutting corners into walls (e.g. the wall inside spawn chambers)
	$NavigationAgent3D.path_desired_distance = 0.5
	$NavigationAgent3D.target_desired_distance = 1.0
	
func start_groan_timer():
	$GroanTimer.wait_time = randf_range(3.0, 7.0)
	$GroanTimer.start()
	
func _on_groan_timer():
	$GroanSound.pitch_scale = randf_range(0.8, 1.1)
	$GroanSound.play()
	start_groan_timer()	
	
func _physics_process(delta):
	var barricade = get_nearest_blocking_barricade()
	if barricade != null:
		_reset_progress()
		velocity.x = 0
		velocity.z = 0
		play_anim("attack")
		time_since_attack += delta
		if time_since_attack >= 2 * attack_cooldown:
			time_since_attack = 0.0
			barricade.break_board()
			print("Zombie ", self, " broke a board at time ", Time.get_ticks_msec())
		velocity.y -= 9.8 * delta
		move_and_slide()
		return
	if is_dying:
		velocity.x = 0
		velocity.z = 0
		velocity.y -= 9.8 * delta
		move_and_slide()
		return
	if is_spawning: 
		var player = get_tree().get_first_node_in_group("player")
		if player: 
			var direction = (player.global_position - global_position)
			direction.y = 0
			direction = direction.normalized()
			velocity.x = direction.x * speed * 0.5 
			velocity.z = direction.z * speed * 0.5 
			var look_target = global_position + direction
			look_at(look_target, Vector3.UP)
		velocity.y -= 9.8 * delta
		move_and_slide()
		return
	time_since_attack += delta
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var to_player = player.global_position - global_position
		to_player.y = 0
		var distance = to_player.length()

		if distance > attack_range:
			if _check_no_progress(delta):
				return
			
			$NavigationAgent3D.target_position = player.global_position

			var next_point = $NavigationAgent3D.get_next_path_position()

			var direction = next_point - global_position
			direction.y = 0

			if direction.length() > 0.001:
				direction = direction.normalized()

				
				check_window_timer += delta
				escape_cooldown = max(0.0, escape_cooldown - delta)
				if not window_started:
					window_start_position = global_position
					window_started = true
				if check_window_timer >= 0.3:
					var net_move = global_position.distance_to(window_start_position)
					check_window_timer = 0.0
					window_start_position = global_position
					if net_move < 0.15:
						stuck_timer += 0.3
						escape_cooldown = 0.6
					else:
						stuck_timer = 0.0

				if stuck_timer > 0.1 or escape_cooldown > 0.0:
					if stuck_timer > 0.1:
						var push = Vector3.ZERO
						for i in get_slide_collision_count():
							push += get_slide_collision(i).get_normal()
						push.y = 0
						if push.length() > 0.01:
							unstuck_dir = push.normalized()
						elif unstuck_dir == Vector3.ZERO:
							unstuck_dir = Vector3(-direction.z, 0, direction.x)
					direction = (direction * 0.25 + unstuck_dir * 1.4).normalized()
				else:
					unstuck_dir = Vector3.ZERO

				velocity.x = direction.x * speed
				velocity.z = direction.z * speed

				play_anim("mixamo_com")

				var look_target = global_position + direction
				look_at(look_target, Vector3.UP)

			else:
				velocity.x = 0
				velocity.z = 0
			
		else:
			# close enough: stop and attack
			_reset_progress()
			velocity.x = 0
			velocity.z = 0
			play_anim("attack")
			if time_since_attack >= attack_cooldown:
				time_since_attack = 0.0
				if player.has_method("take_damage"):
					player.take_damage(attack_damage)

	velocity.y -= 9.8 * delta
	move_and_slide()
	#$screams.play()
	
func play_anim(anim_name):
	if anim_name == "death":
		zombie_run.stop()
		zombie_attack.stop()
		if zombie_death.current_animation != "death":
				zombie_death.play("death")
	elif anim_name == "attack":
		zombie_run.stop()
		zombie_death.stop()
		if zombie_attack.current_animation != "attack":
			zombie_attack.play("attack")
			zombie_attack.speed_scale=2
	else:
		zombie_attack.stop()
		zombie_death.stop()
		
		if zombie_run.current_animation != anim_name:
				zombie_attack.stop()
				zombie_run.play(anim_name)
				zombie_run.speed_scale = 1.1
	

		
func take_damage(amount):
	health -= amount
	print("Zombie health: ", health)
	if health <= 0:
		die()
	
var is_dying := false
func die():
	if is_dying:
		return
	is_dying = true
	print("Zombie died!")
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		print("Calling add_gold")
		player.add_gold(20)

	$Body.disabled = true
	set_physics_process(false)
	play_anim("death")	

	await zombie_death.animation_finished
	queue_free()
	
func spawn_zombies():
	play_anim("mixamo_com")
	
	
func _reset_progress():
	progress_timer = 0.0
	progress_origin = Vector3.INF
	no_progress_windows = 0

func _check_no_progress(delta) -> bool:
	if progress_origin == Vector3.INF:
		progress_origin = global_position
	progress_timer += delta
	if progress_timer < PROGRESS_WINDOW:
		return false
	var moved = Vector2(global_position.x - progress_origin.x, global_position.z - progress_origin.z).length()
	progress_timer = 0.0
	progress_origin = global_position
	if moved < MIN_PROGRESS and not _near_intact_barricade():
		no_progress_windows += 1
	else:
		no_progress_windows = 0
	if no_progress_windows >= MAX_NO_PROGRESS_WINDOWS:
		print("Zombie despawned: no progress for ", PROGRESS_WINDOW * MAX_NO_PROGRESS_WINDOWS, "s at ", global_position)
		queue_free()
		return true
	return false

# zombies queued up behind others at a barricade aren't stuck, just waiting
func _near_intact_barricade() -> bool:
	for b in get_tree().get_nodes_in_group("barricades"):
		if b.boards_up > 0 and global_position.distance_to(b.global_position) < 5.0:
			return true
	return false

func get_nearest_blocking_barricade():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return null
		
	var barricades = get_tree().get_nodes_in_group("barricades")
	for b in barricades:
		if b.boards_up <= 0:
			continue
		var dist_to_barricade = global_position.distance_to(b.global_position)
		if dist_to_barricade > 1.5:
			continue
			
		var to_barricade = (b.global_position - global_position).normalized()
		var facing = -global_transform.basis.z
		if facing.dot(to_barricade) > 0.5:
			return b
	return null
