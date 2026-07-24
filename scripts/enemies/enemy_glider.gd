extends Node2D

signal died(card_name)

@export var target_node: Node2D
@export var speed: float = 10.0
@export var health: int = 1
@export var die_sfx: AudioStream

@onready var ani = $AnimationPlayer
@onready var hit_cooldown_timer = $hit_cooldown

var card_name: String
var run_direction: String
var alive = true

func _ready() -> void:
	ani.play("idle")
	
	if target_node and target_node.global_position.x > global_position.x:
		run_direction = "right"
	else:
		run_direction = "left"
		$Sprite2D.flip_h = true

func _process(delta: float) -> void:
	if alive and target_node:
		run(delta)

func run(delta: float) -> void:
	var move_distance = speed * delta
	global_position = global_position.move_toward(target_node.global_position, move_distance)

func die() -> void:
	alive = false
	AudioManager.play_sfx(die_sfx, 1.0, -8.0)
	$Area2D.set_deferred("monitorable", false)
	$Area2D.set_deferred("monitoring", false)
	ani.play("die")

func on_death() -> void:
	died.emit(card_name)
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not hit_cooldown_timer.is_stopped():
		return

	var arrow = area.get_parent()

	var damage = 0
	if "dmg" in arrow:
		damage = arrow.dmg
	elif "DMG" in arrow:
		damage = arrow.DMG

	if damage > 0:
		hit_cooldown_timer.start()
		health -= damage
		
		if health <= 0:
			die()
