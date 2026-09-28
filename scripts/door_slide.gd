extends Node3D

@export var open_offset := Vector3(0, 2.5, 0)
@export var open_duration := 0.6

@onready var closed_position: Vector3 = position
@onready var open_position: Vector3 = closed_position + open_offset

var is_open := false
var tween: Tween

func _ready():
	closed_position = position
	open_position = closed_position + open_offset

func open():
	if is_open:
		return
	is_open = true
	_animate_to(open_position)

func _animate_to(target: Vector3):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target, open_duration)
