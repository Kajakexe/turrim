extends "res://scripts/enemies/enemy_base.gd"

func _ready() -> void:
	$Area2D/CollisionShape2D.disabled = false
	add_to_group("glitch_enemies")
	
	if target_node and target_node.global_position.x > global_position.x:
		run_direction = "right"
		$Sprite2D.flip_h = false
	else:
		run_direction = "left"
		$Sprite2D.flip_h = true
		
	ani.play("run")

func glitch_init() -> void:
	if alive:
		ani.play("glitch")

func glitch() -> void:
	if not alive or not target_node:
		return
		
	# teleport opposite side of target
	var distance_to_target = target_node.global_position.x - global_position.x
	global_position.x = target_node.global_position.x + distance_to_target
	
	# swap direction
	if run_direction == "right":
		run_direction = "left"
		$Sprite2D.flip_h = true
	else:
		run_direction = "right"
		$Sprite2D.flip_h = false

func glitch_finished() -> void:
	ani.play("run")
