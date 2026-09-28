extends Node3D

@export var cost := 0
@export var unlocks_room: String = ""
@export var requires_rooms: Array[String] = []
@export var open_sound: AudioStream
@export var close_sound: AudioStream

var is_open := false
@onready var sound_player: AudioStreamPlayer3D = $right_door/DoorSound
func _ready():
	add_to_group("doors")

func toggle(player = null):
	if is_open:
		return
	if requires_rooms.size() > 0:
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		if wave_manager == null:
			return
		for room in requires_rooms:
			if room not in wave_manager.unlocked_rooms:
				print("This door needs ", room, " cleared first.")
				return
	if cost > 0:
		if player == null or player.gold < cost:
			print("Not enough gold for this door!")
			if player and player.has_method("show_temp_message"):
				player.show_temp_message("Not enough gold! Need %d" % cost, 1.5)
			return
		player.gold -= cost
		player.update_gold_display()

	is_open = true
	_play_sound(open_sound)
	$right_door.open()
	$left_door.open()

	if unlocks_room != "":
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		if wave_manager:
			wave_manager.unlock_room(unlocks_room)

func _play_sound(stream: AudioStream):
	if stream and sound_player:
		sound_player.stream = stream
		sound_player.play()
