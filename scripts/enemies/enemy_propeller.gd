extends "res://scripts/enemies/enemy_glider.gd"

@export var wave_frequency: float = 5.0
@export var wave_amplitude: float = 20.0

var time_passed: float = 0.0

func _ready() -> void:
	super._ready()

func run(delta: float) -> void:
	if not target_node:
		return
		
	time_passed += delta
	
	var target_position = target_node.global_position
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	var move_distance = speed * delta
	
	# calculate forward step
	var movement = direction * min(move_distance, distance)
	
	# calculate wave offset perpendicular to movement
	var wave_dir = Vector2(-direction.y, direction.x)
	var wave_offset = wave_dir * cos(time_passed * wave_frequency) * wave_amplitude * delta
	
	if move_distance >= distance:
		global_position = target_position
	else:
		global_position += movement + wave_offset
