extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.003


var health = 100
var tracer_timer := 0.0
var gold := 0
var jump_velocity = 4
var is_reloading := false
var reload_timer := 0.0
var shake_amount := 0.0
var recoil_velocity := 0.0
var bob_time := 0.0
var time_since_damage := 0.0
@export var regen_delay := 10.0
@export var regen_rate := 4.0
@export var max_health := 100
@export var bob_frequency := 1.0
@export var bob_amplitude := 0.08
@export var bob_side_amplitude := 0.05
@onready var cam_home = $Camera3D.position
@onready var gun_holder_home: Vector3 = $Camera3D/GunHolder.position
var gun_kick_offset := Vector3.ZERO
var crosshair_flash_timer := 0.0
var camera_pitch := 0.0
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const BULLET_SPEED := 80.0



var weapons = {
	"pistol": {
		"damage": 20,
		"fire_rate": 0.3,
		"automatic": false,
		"sound": preload("res://sounds/pistol_shot.wav"),
		"reload_sound": preload("res://sounds/pistol_reload.mp3"),
		"ammo": 12,
		"mag_size": 12,
		"range": 20,
		"recoil" : 0.15,
		"kick" : 0.08,
		"reserve_ammo" : 999999
	},
	"shotgun": {
		"damage": 25,
		"fire_rate": 0.8,
		"pellets": 8,
		"automatic": false,
		"sound": preload("res://sounds/shotgun_shot.wav"),
		"reload_sound": preload("res://sounds/shotgun_reload.wav"),
		"ammo": 4,
		"mag_size": 4,
		"range": 4,
		"recoil" : 1.0,
		"kick" : 0.1,
		"reserve_ammo" : 16
	},
	"rifle": {
		"damage" : 30,
		"fire_rate": 0.05,
		"automatic": true,
		"ammo": 36,
		"mag_size" : 36,
		"range": 60,
		"recoil" : 0.2,
		"kick" : 0.05,
		"reserve_ammo" : 72,
		"sound" : preload("res://sounds/rifle_shot_trimmed.wav"),
		"reload_sound": preload("res://sounds/rifle_reload.mp3"),
	},
	"sniper": {
		"damage" : 100,
		"fire_rate": 1.2,
		"automatic": false,
		"sound": preload("res://sounds/rifle_shot.wav"),
		"ammo": 4,
		"mag_size": 4,
		"range": 60,
		"recoil" : 2.0,
		"kick" : 0.2,
		"reserve_ammo" : 16
	}
}
var current_weapon := "pistol"
var owned_weapons := ["pistol"]
var fire_cooldown := 0.0



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var box = CylinderMesh.new()
	box.top_radius = 0.02
	box.bottom_radius = 0.02
	box.height = 1.0
	$Tracer.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 0)
	mat.emission_energy_multiplier = 5.0
	$Tracer.material_override = mat
	$Tracer.visible = true
	tracer_timer = 0.01
	show_tracer(global_position, global_position + Vector3(0, 0, -1))
	weapon_display()
	update_gun_model()
	update_ammo_count()

	update_blood_overlay()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, -1.5, 1.5)
		$Camera3D.rotation.x = camera_pitch
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# fire immediately on the press itself, don't rely solely on the
		# _process() hold-polling loop below - a fast single click could
		# land between process frames and never register a shot otherwise.
		shoot()
	if event is InputEventKey and event.pressed:
		var key_index = -1
		
		if event.keycode == KEY_1: key_index = 0
		elif event.keycode == KEY_2: key_index = 1
		elif event.keycode == KEY_3: key_index = 2
		elif event.keycode == KEY_4: key_index = 3
		elif event.keycode == KEY_5: key_index = 4
			
		if key_index >= 0 and key_index < owned_weapons.size():
			current_weapon = owned_weapons[key_index]
			weapon_display()
			update_gun_model()
			update_ammo_count()
			$Camera3D/AnimationPlayer.play("switch")
			
	if Input.is_action_just_pressed("reload"):
		start_reload()
		
	
func _physics_process(delta):
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed *= 1.4
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= 16 * delta  # gravity
	move_and_slide()
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1 and is_on_floor():
		bob_time += horizontal_speed * delta * bob_frequency
		
	


	if Input.is_action_pressed("repair"):
		var barricades = get_tree().get_nodes_in_group("barricades")
		for b in barricades:
			if global_position.distance_to(b.global_position) < 3.0:
				b.repair(delta, self)


	if Input.is_action_just_pressed("interact"):
		if reading_note:
			_close_note()
			return
		var notes = get_tree().get_nodes_in_group("notes")
		for n in notes:
			if global_position.distance_to(n.global_position) < 3.0:
				_open_note(n)
				return
		print("E pressed")
		var buys = get_tree().get_nodes_in_group("weapon_shops")
		var doors = get_tree().get_nodes_in_group("doors")
		print("doors found: ", doors.size())
		for c in doors:
			var door_pos = c.get_node("frame").global_position if c.has_node("frame") else c.global_position
			print("door node: ", c.name, " | type: ", c.get_script())
			if global_position.distance_to(door_pos) < 3.0:
				print("calling toggle")
				c.toggle(self)
		for d in buys:
			if global_position.distance_to(d.global_position) < 3.0:
				d.try_buy(self)

	_update_hud_prompts(delta)

var prompt_temp_message := ""
var prompt_temp_timer := 0.0
var in_acid_count := 0
var reading_note := false

func show_temp_message(text: String, duration: float = 1.5):
	prompt_temp_message = text
	prompt_temp_timer = duration

func _open_note(note):
	reading_note = true
	var reader = get_tree().get_first_node_in_group("note_reader")
	if reader:
		reader.show_note(note.note_text)

func _close_note():
	reading_note = false
	var reader = get_tree().get_first_node_in_group("note_reader")
	if reader:
		reader.hide_note()

func enter_acid():
	in_acid_count += 1

func exit_acid():
	in_acid_count = max(0, in_acid_count - 1)

func show_floating_gold(amount: int):
	var gold_label = get_tree().get_first_node_in_group("gold_label")
	if gold_label == null:
		return
	var hud = gold_label.get_parent()
	var popup := Label.new()
	popup.text = "+%d" % amount
	popup.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	popup.add_theme_font_size_override("font_size", 22)
	popup.position = gold_label.position + Vector2(0, 34)
	hud.add_child(popup)
	var tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 36, 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(popup.queue_free)

func _update_hud_prompts(delta):
	var label = get_tree().get_first_node_in_group("message_label")
	if prompt_temp_timer > 0.0:
		prompt_temp_timer -= delta
		if label:
			label.text = prompt_temp_message
	else:
		var best_text := ""
		var best_dist := 3.0
		for d in get_tree().get_nodes_in_group("doors"):
			if d.is_open:
				continue
			var door_pos = d.get_node("frame").global_position if d.has_node("frame") else d.global_position
			var dist = global_position.distance_to(door_pos)
			if dist < best_dist:
				best_dist = dist
				if d.cost > 0:
					best_text = "Press E to open (%d Gold)" % d.cost
				else:
					best_text = "Press E to open"
		for s in get_tree().get_nodes_in_group("weapon_shops"):
			var dist = global_position.distance_to(s.global_position)
			if dist < best_dist:
				best_dist = dist
				best_text = "Press E to interact"
		for b in get_tree().get_nodes_in_group("barricades"):
			if b.boards_up >= b.max_boards:
				continue
			var dist = global_position.distance_to(b.global_position)
			if dist < best_dist:
				best_dist = dist
				best_text = "Hold SHIFT to repair"
		for n in get_tree().get_nodes_in_group("notes"):
			var dist = global_position.distance_to(n.global_position)
			if dist < best_dist:
				best_dist = dist
				best_text = "Press E to read the note"
		if label and not reading_note:
			label.text = best_text

	var acid_label = get_tree().get_first_node_in_group("acid_warning_label")
	if acid_label:
		acid_label.visible = in_acid_count > 0

			
func start_reload():
	var weapon = weapons[current_weapon]
	if is_reloading or weapon["ammo"] >= weapon["mag_size"] or weapon["reserve_ammo"] <= 0:
		return
	
	is_reloading = true
	reload_timer = 1.5
	var reload_sound = weapon.get("reload_sound")
	if reload_sound:
		reload_timer = reload_sound.get_length()
		$ReloadSound.stream = reload_sound
		$ReloadSound.play()
	$Camera3D/AnimationPlayer.play("switch")
	print("reloading...")
					

func finish_reload():
	var weapon = weapons[current_weapon]
	var needed = weapon["mag_size"] - weapon["ammo"]
	var take = min(needed, weapon["reserve_ammo"])
	weapon["ammo"] += take
	weapon["reserve_ammo"] -= take
	is_reloading = false
	update_ammo_count()
	print("reloaded")
		
func _play_shot_sound(stream: AudioStream):
	$GunSound.stream = stream
	$GunSound.pitch_scale = randf_range(0.9, 1.1)
	$GunSound.play()

var auto_fire_voice_index := 0

func _play_auto_fire_sound(stream: AudioStream):
	# fire_rate can be shorter than the clip itself (rapid-fire weapons), so a
	# single AudioStreamPlayer3D would just cut its own previous shot short
	# every time. Round-robin a small pool instead so each shot is actually
	# heard in full, the way overlapping real automatic-fire recordings sound.
	var pool = $AutoFireSoundPool
	var voice = pool.get_child(auto_fire_voice_index)
	auto_fire_voice_index = (auto_fire_voice_index + 1) % pool.get_child_count()
	voice.stream = stream
	voice.pitch_scale = randf_range(0.95, 1.05)
	voice.volume_db = 20.0  # +12dB over the pool's base -6dB = ~4x the amplitude
	voice.play()

func shoot():
	var weapon = weapons[current_weapon]

	if fire_cooldown > 0 or weapon["ammo"] == 0 or is_reloading or reading_note:
		return


	fire_cooldown = weapon["fire_rate"]
	recoil_velocity += weapon.get("recoil", 2.0)
	_eject_casing()
	gun_kick_offset += Vector3(0, 0, weapon.get("kick", 0.15))
	if weapon.get("automatic", false):
		_play_auto_fire_sound(weapon["sound"])
	else:
		_play_shot_sound(weapon["sound"])
	weapon["ammo"] -= 1
	update_ammo_count()
	var pellets = weapon.get("pellets", 1)
	for i in pellets:
		fire_one_ray(weapon["damage"], pellets > 1)
		
	
func flash_crosshair():
	crosshair_flash_timer = 0.3
	var crosshair = get_tree().get_first_node_in_group("crosshair")
	if crosshair: 
		crosshair.modulate = Color(1, 0, 0)
		
	
func _eject_casing():
	var muzzle = $Camera3D/GunHolder.get_node(current_weapon + "/Muzzle")	
	var casing = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(casing)
	casing.global_position = muzzle.global_position
	casing.use_gravity = true
	casing.velocity = $Camera3D.global_transform.basis.x * randf_range(1.0, 2.0) + Vector3(0, 2.0, 0)
	casing.lifetime = 0.60 
	casing.look_at(casing.global_position + casing.velocity.normalized(), Vector3.UP)
	

func update_ammo_count():
	var label = get_tree().get_first_node_in_group("ammo_label")
	if label:
		
		var weapon = weapons[current_weapon]
		if current_weapon == "pistol":
			label.text = "Ammo: " + str(weapon["ammo"]) + "/" + str(weapon["mag_size"]) + "(∞)"
		else: 
			label.text = "Ammo: " + str(weapon["ammo"]) + "/" + str(weapon["mag_size"]) + " (" + str(weapon['reserve_ammo']) + ")"
	
func buy_ammo(weapon_name: String, amount: int, cost: int) -> bool:
	if gold < cost:
		return false
	gold -= cost
	weapons[weapon_name]["reserve_ammo"] += amount
	update_gold_display()
	update_ammo_count()
	return true
	
	
func fire_one_ray(damage, spread):
	var muzzle = $Camera3D/GunHolder.get_node(current_weapon + "/Muzzle")
	var direction = -$Camera3D.global_transform.basis.z
	if spread:
		direction = direction.rotated(Vector3.UP, randf_range(-0.05, 0.05))

	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.velocity = direction.normalized() * BULLET_SPEED
	bullet.damage = damage
	bullet.look_at(bullet.global_position + direction, Vector3.UP)
	bullet.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(90))
	$MuzzleSmoke.global_position = muzzle.global_position
	$MuzzleSmoke.restart()

		
func show_tracer(start, end): 
	var mesh = $Tracer
	var distance = start.distance_to(end)
	mesh.global_position = (start + end) / 2
	mesh.look_at(end, Vector3.UP)
	mesh.rotate_object_local(Vector3(1, 0, 0), deg_to_rad(90))
	mesh.scale = Vector3(1, distance, 1)   # stretch the length-1 box to fit
	mesh.visible = true
	tracer_timer = 0.1
	
func add_gold(amount):
	gold += amount
	print("Gold: ", gold)
	update_gold_display()
	
func update_health_display():
	if not is_inside_tree():
		return
	var hp = get_tree().get_first_node_in_group("health_label")
	if hp: 
		hp.text = "Health: " + str(roundi(health))
	update_blood_overlay()
	
func update_blood_overlay():
	var blood = get_tree().get_first_node_in_group("blood_overlay")
	if blood:
		var t = 0.6 * (1.0 - (float(health / 100.0)))
		
		blood.modulate.a = clamp(t, 0.0, 1.0)

var is_dead := false

func die():
	if is_dead:
		return
	is_dead = true
	print("YOU DIED!")
	var screen = get_tree().get_first_node_in_group("game_over_screen")
	if screen:
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		var wave_text = ""
		if wave_manager:
			wave_text = "You reached wave " + str(wave_manager.current_round)
		screen.show_screen("YOU DIED", wave_text)
	else:
		get_tree().reload_current_scene()

func update_gold_display():
	var label = get_tree().get_first_node_in_group("gold_label")
	if label:
		label.text = "Gold: " + str(gold)
		
func weapon_display():
	var label = get_tree().get_first_node_in_group("weapon_label")
	if label:
		label.text = "Weapon: " + str(current_weapon)
		
func update_gun_model():
	$Camera3D/GunHolder/pistol.visible = (current_weapon == "pistol")
	$Camera3D/GunHolder/shotgun.visible = (current_weapon == "shotgun")
	$Camera3D/GunHolder/sniper.visible = (current_weapon == "sniper")
	$Camera3D/GunHolder/rifle.visible = (current_weapon == "rifle")
func _process(delta):
	var bob_offset = Vector3(
		sin(bob_time) * bob_side_amplitude,
		abs(sin(bob_time * 2.0)) * bob_amplitude,
		0
	)
	
	if shake_amount > 0:
		shake_amount -= delta * 5.0 
		var shake_offset = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			0
		) * shake_amount * 0.05
		$Camera3D.position = cam_home + bob_offset + shake_offset
	else:
		$Camera3D.position = cam_home + bob_offset
	if weapons[current_weapon].get("automatic", false):
		var weapon = weapons[current_weapon]
		var holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var can_fire = holding and fire_cooldown <= 0 and weapon["ammo"] > 0 and not is_reloading
		if can_fire:
			shoot()
	if crosshair_flash_timer > 0:
		crosshair_flash_timer -= delta
		if crosshair_flash_timer <= 0:
			var crosshair = get_tree().get_first_node_in_group("crosshair")
			if crosshair:
				crosshair.modulate = Color(1, 1, 1)
	
	if tracer_timer > 0:
		tracer_timer -= delta
		if tracer_timer <= 0:
			$Tracer.visible = false
			
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	time_since_damage += delta
	if time_since_damage >= regen_delay and health < max_health:
		health = min(health + regen_rate * delta, max_health)
		update_health_display()
			
	
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()
			
	if recoil_velocity != 0.0:
		camera_pitch += recoil_velocity * delta
		camera_pitch = clamp(camera_pitch, -1.5, 1.5)
		$Camera3D.rotation.x = camera_pitch
		recoil_velocity = lerp(recoil_velocity, 0.0, delta * 8.0)
		if abs(recoil_velocity) < 0.001:
			recoil_velocity = 0.0
	gun_kick_offset = gun_kick_offset.lerp(Vector3.ZERO, delta * 12.0)
	$Camera3D/GunHolder.position = gun_holder_home + gun_kick_offset
	
func take_damage(amount):
	health -= amount
	time_since_damage = 0.0
	shake_amount = 1.0
	print("Player health: ", health)
	if health <= 0:
		die()
	update_health_display()
