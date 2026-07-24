extends Node2D

signal died(card_name: String)

@export var target_node: Node2D
@export var speed: float = 20.0
@export var health: int = 1
@export var die_sfx: AudioStream

@onready var ani: AnimationPlayer = $AnimationPlayer
@onready var hit_cooldown_timer: Timer = $hit_cooldown
@onready var sprite: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

var card_name: String
var run_direction: String = "right"
var alive: bool = true

func _ready() -> void:
	if target_node and target_node.global_position.x < global_position.x:
		run_direction = "left"
		sprite.flip_h = true
		ani.play("run_left")
	else:
		run_direction = "right"
		ani.play("run")

func _process(delta: float) -> void:
	if alive:
		run(delta)

func run(delta: float) -> void:
	var direction_multiplier = 1.0 if run_direction == "right" else -1.0
	global_position.x += speed * delta * direction_multiplier

func die() -> void:
	alive = false
	AudioManager.play_sfx(die_sfx, 1.0, -8.0)
	area_2d.set_deferred("monitorable", false)
	area_2d.set_deferred("monitoring", false)
	ani.play("die")

func on_death() -> void:
	died.emit(card_name)
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not hit_cooldown_timer.is_stopped():
		return

	var arrow = area.get_parent()

	# support lowercase dmg and uppercase DMG
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
