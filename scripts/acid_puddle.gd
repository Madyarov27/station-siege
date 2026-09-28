extends Area3D

@export var damage_per_tick := 5
@export var tick_interval := 0.5

func _ready():
	$Timer.wait_time = tick_interval
	$Timer.timeout.connect(_on_tick)
	$Timer.start()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_tick():
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage_per_tick)

func _on_body_entered(body):
	if body.has_method("enter_acid"):
		body.enter_acid()

func _on_body_exited(body):
	if body.has_method("exit_acid"):
		body.exit_acid()
