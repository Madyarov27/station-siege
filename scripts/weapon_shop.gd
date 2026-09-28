extends Node3D

@export var weapon_name := "shotgun"
@export var cost := 500
@export var ammo_refill_amount := 30
@export var ammo_refill_cost := 100


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("weapon_shops")
	if has_node("ShopLabel"):
		$ShopLabel.text = "▼\n" + weapon_name.to_upper()

func try_buy(player):
	if player.owned_weapons.has(weapon_name):
		_refill_ammo(player)
		return 
	else:
		_buy_weapon(player)

func _buy_weapon(player):
	if player.gold >= cost:
		player.gold -= cost
		player.owned_weapons.append(weapon_name)
		player.current_weapon = weapon_name
		player.update_gold_display()
		player.update_ammo_count()
		player.weapon_display()
		print("bought ", weapon_name)
		$Purchase_sound.play()
		player.update_gun_model()
	else:
		if player.has_method("show_temp_message"):
			player.show_temp_message("Not enough gold! Need %d" % cost, 1.5)

func _refill_ammo(player):
	if player.gold < ammo_refill_cost:
		if player.has_method("show_temp_message"):
			player.show_temp_message("Not enough gold! Need %d" % ammo_refill_cost, 1.5)
		return
	player.gold -= ammo_refill_cost
	player.weapons[weapon_name]["reserve_ammo"] += ammo_refill_amount
	player.update_gold_display()
	player.update_ammo_count()
	$Purchase_sound.play()
	print("Refilled ", weapon_name, "ammo!")
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
