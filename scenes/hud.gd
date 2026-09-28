extends CanvasLayer

func _ready():
	var vp = get_viewport().get_visible_rect().size

	$HealthLabel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$HealthLabel.position = Vector2(vp.x * 0.02, vp.y * 0.88)

	$WeaponLabel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$WeaponLabel.position = Vector2(vp.x * 0.02, vp.y * 0.94)

	$AmmoLabel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$AmmoLabel.position = Vector2(vp.x * 0.80, vp.y * 0.90)

	$GoldLabel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$GoldLabel.position = Vector2(vp.x * 0.85, vp.y * 0.03)

	$WaveLabel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	$WaveLabel.position = Vector2(vp.x * 0.40, vp.y * 0.05)

	$MessageLabel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	$MessageLabel.position = Vector2(vp.x * 0.5 - 200, vp.y * 0.78)
	$MessageLabel.size = Vector2(400, 32)

	$AcidWarningLabel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	$AcidWarningLabel.position = Vector2(vp.x * 0.5 - 200, vp.y * 0.72)
	$AcidWarningLabel.size = Vector2(400, 32)
