class_name EnemyData
extends RefCounted

const POOL: Dictionary = {
	"base":         {"scene": preload("res://scenes/enemies/enemy_base.tscn"),         "cost": 2, "motion": "floor", "color": "red"},
	"glider":       {"scene": preload("res://scenes/enemies/enemy_glider.tscn"),       "cost": 2, "motion": "air",   "color": "blue"},
	"helmet_speer": {"scene": preload("res://scenes/enemies/enemy_helmet.tscn"),       "cost": 3, "motion": "floor", "color": "red"},
	"helmet_axe":   {"scene": preload("res://scenes/enemies/enemy_helmet_axe.tscn"),   "cost": 4, "motion": "floor", "color": "red"},
	"propeller":    {"scene": preload("res://scenes/enemies/enemy_propeller.tscn"),    "cost": 4, "motion": "air",   "color": "blue"},
	"helmet_knife": {"scene": preload("res://scenes/enemies/enemy_helmet_knife.tscn"), "cost": 5, "motion": "floor", "color": "red"},
	"glitch":       {"scene": preload("res://scenes/enemies/enemy_glitch.tscn"),       "cost": 6, "motion": "floor", "color": "lila"},
	"big":          {"scene": preload("res://scenes/enemies/enemy_big.tscn"),          "cost": 7, "motion": "floor", "color": "red"},
	"shield":       {"scene": preload("res://scenes/enemies/enemy_shield.tscn"),       "cost": 7, "motion": "floor", "color": "lila"},
	"triplets":     {"scene": preload("res://scenes/enemies/enemy_triplets.tscn"),     "cost": 8, "motion": "floor", "color": "red"},
}
