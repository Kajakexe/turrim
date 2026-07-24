extends Control
class_name VolumeBar

@export var bus_name: String = "Master"
@export var block_texture: Texture2D
@export var max_blocks: int = 10
@export var block_spacing: float = 4.0

const COLOR_ON: Color = Color("d9cdaaff")
const COLOR_OFF: Color = Color("3b3430")

var current_blocks: int = 7:
	set(value):
		current_blocks = clampi(value, 0, max_blocks)
		_update_blocks_visuals()
		_update_bus_volume()

var bus_index: int = 0
var is_dragging: bool = false
var block_nodes: Array[TextureRect] = []

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	_build_bar()
	
	# sync initial volume from audio server
	var db: float = AudioServer.get_bus_volume_db(bus_index)
	var linear: float = db_to_linear(db)
	current_blocks = int(round(linear * max_blocks))

func _build_bar() -> void:
	for child in get_children():
		child.queue_free()
	block_nodes.clear()

	if not block_texture:
		return

	var single_height: float = block_texture.get_height() + block_spacing
	
	for i in range(max_blocks):
		var rect := TextureRect.new()
		rect.texture = block_texture
		rect.position = Vector2(0, i * single_height)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		block_nodes.append(rect)

	_update_blocks_visuals()

func _update_blocks_visuals() -> void:
	# block 0 is top (100%), fill active blocks from bottom up
	for i in range(block_nodes.size()):
		var block_level_from_bottom: int = max_blocks - i
		if block_level_from_bottom <= current_blocks:
			block_nodes[i].modulate = COLOR_ON
		else:
			block_nodes[i].modulate = COLOR_OFF

func _update_bus_volume() -> void:
	var linear_val: float = float(current_blocks) / float(max_blocks)
	var db_val: float = linear_to_db(linear_val)
	AudioServer.set_bus_volume_db(bus_index, db_val)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
		if is_dragging:
			_calculate_volume_from_mouse(event.position)

	elif event is InputEventMouseMotion and is_dragging:
		_calculate_volume_from_mouse(event.position)

func _calculate_volume_from_mouse(mouse_pos: Vector2) -> void:
	if block_nodes.is_empty() or not block_texture:
		return

	var single_block_height: float = block_texture.get_height() + block_spacing
	var total_height: float = single_block_height * max_blocks
	
	var clamped_y: float = clampf(mouse_pos.y, 0.0, total_height)
	var height_from_bottom: float = total_height - clamped_y
	var target_block: int = int(ceil(height_from_bottom / single_block_height))
	
	current_blocks = target_block
