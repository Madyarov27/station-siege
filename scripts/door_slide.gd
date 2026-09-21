extends Node3D


@export var open_offset := Vector3(0, 2.5, 0) 
@export var open_duration := 0.6
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var unlocks_room: String = ""
@onready var closed_position: Vector3 = position
@onready var open_position: Vector3 = closed_position + open_offset
@onready var sound_player: AudioStreamPlayer3D = $DoorSound

var is_open := false
var tween: Tween

func _ready():
	add_to_group("doors")
	closed_position = position
	open_position = closed_position + open_offset


func toggle():
	open()
	print("Door toggled. unlocks_room = '", unlocks_room, "'")
	if unlocks_room != "":
		var wave_manager = get_tree().get_first_node_in_group("wave_manager")
		print("wave_manager found: ", wave_manager)
		if wave_manager:
			wave_manager.unlock_room(unlocks_room)
			print("ROOM UNLOCKED: " + unlocks_room)
func open():
	if is_open:
		return
	is_open = true
	_play_sound(open_sound)
	_animate_to(open_position)
	
	
	
func close():
	return
	
	
	
func _animate_to(target: Vector3):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target, open_duration)
	
	
func _play_sound(stream: AudioStream):
	if stream and sound_player:
		sound_player.stream = stream
		sound_player.play()
		
		
