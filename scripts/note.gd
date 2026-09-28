extends Node3D

@export_multiline var note_text := "Dear Albert,

If you are reading this, know that there is hope. Sector C got overrun by biological horror after the containment faced catastrophic failure. Everyone was forced to evacuate and we couldn't get to you. Survive 10 waves and the rescue will arrive by that time. There is a shotgun at cargo bay and a machine gun at the bridge. Fetch them and your survival chances will increase. Be cautious. Those pests are lurking in every shadow of the station. Do not let them surround you from all sides, and always stay in motion. Still = dead.

Do not lose faith. We will get back to you eventually."

func _ready():
	add_to_group("notes")
