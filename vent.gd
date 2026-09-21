extends StaticBody3D


@export var max_health: int = 6

var health: int 
var is_broken := false
var home_pos: Vector3
var home_rot: Vector3 

@onready var vent_model := $VentModel
@onready var col := $CollisionShape3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("barricades ")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
