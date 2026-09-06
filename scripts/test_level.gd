extends Node2D

const PlatformScene := preload("res://scenes/platform.tscn")
const PlayerScene := preload("res://scenes/player.tscn")
const TILE := 64


func _ready() -> void:
	_add_platform(Vector2(0, 8 * TILE), 12, 4)
	_add_platform(Vector2(16 * TILE, 8 * TILE), 14, 4)
	_add_platform(Vector2(8 * TILE, 5 * TILE), 3, 1)
	_add_platform(Vector2(20 * TILE, 4 * TILE), 3, 1)
	_add_platform(Vector2(26 * TILE, 2 * TILE), 4, 1)
	_add_platform(Vector2(-2 * TILE, 16 * TILE), 36, 2)

	var player := PlayerScene.instantiate()
	player.position = Vector2(3 * TILE, 6 * TILE)
	add_child(player)


func _add_platform(top_left: Vector2, tiles_x: int, tiles_y: int) -> void:
	var platform := PlatformScene.instantiate() as GrassPlatform
	platform.position = top_left
	platform.tiles_x = tiles_x
	platform.tiles_y = tiles_y
	add_child(platform)
