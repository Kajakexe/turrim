class_name CardDatabase

const COLOR_OFFSETS: Dictionary = {
	"red": 0,
	"blue": 1,
	"lila": 2
}

static func get_card_frame(cost: int, color: String) -> int:
	var value_index: int = cost - 2
	var color_offset: int = COLOR_OFFSETS.get(color, 0)
	return (value_index * 4) + color_offset

static func get_card_data_for_enemy(enemy_key: String, enemy_pool: Dictionary) -> Dictionary:
	if not enemy_pool.has(enemy_key):
		return {}
		
	var data: Dictionary = enemy_pool[enemy_key]
	var cost: int = data.get("cost", 2)
	var color: String = data.get("color", "red")
	
	return {
		"enemy_key": enemy_key,
		"value": cost,
		"color": color,
		"frame": get_card_frame(cost, color)
	}
