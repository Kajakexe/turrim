extends Node2D

var speed_multiplier: float = 5.0 
var velocity: Vector2 = Vector2.ZERO
var is_flying: bool = false
var dmg: int = 1
var gravity: float = 600.0

@onready var area_2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var shot_vector: Vector2 = Vector2.ZERO:
	set(value):
		shot_vector = value * 1.2
		velocity = shot_vector * speed_multiplier
		is_flying = true

func _physics_process(delta: float) -> void:
	if is_flying:
		# add gravity
		velocity.y += gravity * delta
		# rotate to movement path
		global_rotation = velocity.angle()
		# move node
		global_position += velocity * delta

func die() -> void:
	is_flying = false
	animation_player.play("die")

func on_death() -> void:
	queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	_disable_area()
	
	if area.is_in_group("sticky"):
		is_flying = false
		var sprite = area.get_parent().get_node("Sprite2D")
		call_deferred("reparent", sprite)
	else:
		die()

func _on_area_2d_body_entered(_body: Node2D) -> void:
	_disable_area()
	die()

func _disable_area() -> void:
	area_2d.set_deferred("monitorable", false)
	area_2d.set_deferred("monitoring", false)
