extends "res://scripts/enemies/enemy_base.gd"

@export var helmet_speed: float = 10.0

@onready var ani_helmet = $ani_helmet

var new_speed = speed

func _ready() -> void:
	new_speed = speed
	super()
	speed = helmet_speed
	ani_helmet.play("run")

func _on_area_2d_area_entered(area: Area2D) -> void:
	super(area)
	if health == 1:
		match run_direction:
			"right":
				ani_helmet.play("die")
			"left":
				ani_helmet.play("die_left")
		speed = new_speed
