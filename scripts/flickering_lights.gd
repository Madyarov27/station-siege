extends Node3D

@export var flicker_enabled := true
@export var min_energy := 0.3
@export var max_energy := 1.0
@export var flicker_speed := 0.1

var lights: Array[Light3D] = []
var base_energies: Array[float] = []
var timer := 0.0

func _ready():
	_find_lights(self)
	for l in lights:
		base_energies.append(l.light_energy)

func _find_lights(node: Node):
	for child in node.get_children():
		if child is Light3D:
			lights.append(child)
		_find_lights(child)

func _process(delta):
	if not flicker_enabled:
		return
	timer -= delta
	if timer <= 0.0:
		timer = flicker_speed
		for i in lights.size():
			lights[i].light_energy = randf_range(min_energy, max_energy) * base_energies[i]
