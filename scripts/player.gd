extends Node2D

@export var bow_release_sfx: AudioStream

@export var mouse_sensitivity: float = 0.45
@export var max_draw_distance: float = 80.0
@export var release_speed: float = 15.0

@export_group("Trajectory Line FX")
@export var start_radius: float = 15.0
@export var start_width: float = 4.0
@export var expand_factor: float = 3.0
@export var base_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var border_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var border_thickness: float = 1.0

@onready var bow_sprite: Sprite2D = $anchor/bow
@onready var arrow_sprite: Sprite2D = $anchor/arrow_fake
@onready var cooldown_timer: Timer = $cooldown
@onready var anchor: Node2D = $anchor
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var arrow_container: Node2D = $arrows

var is_drawing: bool = false
var is_releasing: bool = false
var able_to_shoot: bool = true
var off: bool = true

var draw_vector: Vector2 = Vector2.ZERO
var shot_vector: Vector2 = Vector2.ZERO

const ARROW_SCENE = preload("res://scenes/arrow.tscn")

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if off:
		return
	
	if is_releasing:
		draw_vector = draw_vector.lerp(Vector2.ZERO, release_speed * delta)
		
		if draw_vector.length() > 1.0:
			anchor.rotation = draw_vector.angle() + PI
		
		queue_redraw()
		
		if draw_vector.length() <= start_radius:
			is_releasing = false
			draw_vector = Vector2.ZERO
			queue_redraw()
			arrow_sprite.visible = false
			shoot_arrow()

func _unhandled_input(event: InputEvent) -> void:
	if off:
		return
	
	if event.is_action_pressed("click") and able_to_shoot:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		is_drawing = true
		is_releasing = false
		draw_vector = Vector2.ZERO
		arrow_sprite.visible = true
		queue_redraw()
		
	elif event is InputEventMouseMotion and is_drawing:
		draw_vector += event.relative * mouse_sensitivity
		draw_vector = draw_vector.limit_length(max_draw_distance)
		
		player_sprite.flip_h = draw_vector.x >= 0
		anchor.rotation = draw_vector.angle() + PI
		queue_redraw()
		
	elif event.is_action_released("click") and is_drawing:
		is_drawing = false
		is_releasing = true
		shot_vector = -draw_vector

func shoot_arrow() -> void:
	able_to_shoot = false
	cooldown_timer.start()
	
	AudioManager.play_sfx(bow_release_sfx)
	get_tree().call_group("glitch_enemies", "glitch_init")
	
	var arrow_instance = ARROW_SCENE.instantiate()
	arrow_instance.shot_vector = shot_vector
	arrow_container.add_child(arrow_instance)
	arrow_instance.global_position = arrow_sprite.global_position
	arrow_instance.global_rotation = arrow_sprite.global_rotation + deg_to_rad(90.0)

func _draw() -> void:
	var current_length: float = draw_vector.length()
	
	if (is_drawing or is_releasing) and current_length > start_radius:
		var shot_dir: Vector2 = draw_vector.normalized()
		var perp_dir: Vector2 = Vector2(-shot_dir.y, shot_dir.x)
		
		var power_ratio: float = clampf((current_length - start_radius) / (max_draw_distance - start_radius), 0.0, 1.0)
		_handle_bow_animation(power_ratio)
		
		var dynamic_expand_width: float = lerp(0.0, start_width * expand_factor, power_ratio)
		var end_width: float = start_width + dynamic_expand_width
		
		var start_base: Vector2 = shot_dir * start_radius
		var point_a: Vector2 = start_base + (perp_dir * start_width / 2.0)
		var point_b: Vector2 = start_base - (perp_dir * start_width / 2.0)
		
		var end_base: Vector2 = draw_vector
		var point_c: Vector2 = end_base - (perp_dir * end_width / 2.0)
		var point_d: Vector2 = end_base + (perp_dir * end_width / 2.0)
		
		var polygon_points := PackedVector2Array([point_a, point_b, point_c, point_d])
		
		var dynamic_color: Color = base_color
		dynamic_color.a = lerp(1.0, 0.4, power_ratio)
		
		draw_colored_polygon(polygon_points, dynamic_color)
		
		var border_points := PackedVector2Array([point_a, point_b, point_c, point_d, point_a])
		draw_polyline(border_points, border_color, border_thickness, false)

func _handle_bow_animation(ratio: float) -> void:
	# match animation frame to draw pull progress
	var wanted_frame: int = clampi(int(lerp(0.0, 4.0, ratio)), 0, 3)
	bow_sprite.frame = wanted_frame
	
	var arrow_positions: Array[float] = [16.0, 15.0, 13.0, 10.0]
	arrow_sprite.position.x = arrow_positions[wanted_frame]

func _on_cooldown_timeout() -> void:
	able_to_shoot = true
