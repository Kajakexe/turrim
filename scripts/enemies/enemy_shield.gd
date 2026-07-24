extends "res://scripts/enemies/enemy_base.gd"

@onready var shield_hitbox = $shield_hitbox

func _ready() -> void:
	super()
	
	match run_direction:
		"right":
			shield_hitbox.position.x = 12
		"left":
			shield_hitbox.position.x = -10
