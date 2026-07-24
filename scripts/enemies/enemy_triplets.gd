extends Node2D

signal died(card_name: String)

@export var target_node: Node2D

@export var speed3: float = 60.0
@export var speed2: float = 45.0
@export var speed1: float = 30.0
@export var health: int = 3
@export var die_sfx: AudioStream

@onready var ani = $AnimationPlayer
@onready var ani_tree = $AnimationTree
@onready var state_machine = ani_tree["parameters/playback"]
@onready var hit_cooldown_timer = $hit_cooldown

var card_name: String
var current_speed: float = speed3
var run_direction: String
var alive: bool = true

func _ready() -> void:
	if not alive:
		return
		
	current_speed = speed3
	
	if target_node and target_node.global_position.x > global_position.x:
		run_direction = "right"
	else:
		run_direction = "left"
		scale.x = -1

func _process(delta: float) -> void:
	if alive:
		run(delta)

func run(delta: float) -> void:
	match run_direction:
		"right":
			global_position.x += current_speed * delta
		"left":
			global_position.x -= current_speed * delta

func _on_area_2d_area_entered(area: Area2D) -> void:
	handle_hit(area, "bottom")

func _on_area_2d_2_area_entered(area: Area2D) -> void:
	handle_hit(area, "middle")

func _on_area_2d_3_area_entered(area: Area2D) -> void:
	handle_hit(area, "top")

func handle_hit(area: Area2D, hit_position: String) -> void:
	if not alive or not hit_cooldown_timer.is_stopped():
		return
		
	var arrow = area.get_parent()
	if not arrow:
		return
		
	var damage = 0
	if "dmg" in arrow:
		damage = arrow.dmg
	elif "DMG" in arrow:
		damage = arrow.DMG
		
	if damage > 0:
		hit_cooldown_timer.start()
		
		if die_sfx:
			AudioManager.play_sfx(die_sfx, 1.0, -8.0)
		
		var health_before_hit = health
		health -= damage
		
		arrow.queue_free()
		
		if health <= 0:
			alive = false
			state_machine.travel("die")
		elif health_before_hit == 3:
			current_speed = speed2
			state_machine.travel("run_3_" + hit_position)
		elif health_before_hit == 2:
			current_speed = speed1
			var target_anim = "top" if hit_position in ["top", "middle"] else "bottom"
			state_machine.travel("run_2_" + target_anim)

func on_death() -> void:
	died.emit(card_name)
	queue_free()
