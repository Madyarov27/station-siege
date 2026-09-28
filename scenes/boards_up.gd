extends Node3D

var max_boards := 6
var boards_up := 6
var repair_timer := 0.0
var repair_interval := 1.0 # zombies break one board every 2*attack_cooldown (2.0s); this is half that, so repair is 2x as fast



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("barricades")
	update_boards()

func break_board():
	if boards_up > 0:
		boards_up -= 1
		update_boards()
		$BreakingSound.pitch_scale = randf_range(0.8, 1.2) 
		$BreakingSound.play()
		print("Board broken!! Boards left:  ", boards_up)
		
func repair(delta, player):
	if boards_up < max_boards:
		repair_timer += delta
		if repair_timer >= repair_interval:
			repair_timer = 0.0
			boards_up += 1
			update_boards()
			$RepairSound.pitch_scale = randf_range(0.8, 1.2)
			$RepairSound.play()
			player.gold += 10
			player.update_gold_display()
			if player.has_method("show_floating_gold"):
				player.show_floating_gold(10)
			print("Board repaired: boards left: ", boards_up)
	
	
func update_boards():
	for i in max_boards:
		var board = get_child(i)
		var up = i < boards_up
		board.visible = up
		# a broken board must stop physically blocking movement too - it was
		# only ever going invisible before, leaving its collision solid.
		board.get_node("StaticBody3D/CollisionShape3D").disabled = not up
	# the visual rods are thin and sparse (gaps a capsule can slip through even
	# with correct collision layers), so a separate full-coverage invisible
	# panel does the actual blocking. It stays solid as long as any board is
	# up (matching zombie.gd's own "still blocking" check) and only opens once
	# the barricade is fully broken.
	$BarrierCollision/CollisionShape3D.disabled = boards_up <= 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
