extends Area3D

var velocity := Vector3.ZERO
var damage := 10
var lifetime := 3.0
var use_gravity := false

func _physics_process(delta):
	var from = global_position
	var to = from + velocity * delta
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		var body = result.collider
		if body.has_method("take_damage"):
			var hit_height = result.position.y - body.global_position.y
			var dmg = damage * 3 if hit_height > 1.4 else damage
			body.take_damage(dmg)
			
			if body.has_method("get") and body.health <= 0:
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("flash_crosshair"):
					player.flash_crosshair()
		queue_free()
		return
	global_position = to
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
