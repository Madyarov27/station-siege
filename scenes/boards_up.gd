extends Node3D

var max_boards := 6
var boards_up := 6
var repair_timer := 0.0
var repair_interval := 0.8 



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
			print("Board repaired: boards left: ", boards_up)
	
	
func update_boards():
	for i in max_boards:
		var board = get_child(i)
		board.visible = i < boards_up


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
