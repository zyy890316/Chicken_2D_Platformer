class_name GrassPlatform
extends StaticBody2D

enum Terrain { GRASS, DIRT, STONE }

const TILE := 64
const TEX_TOP := {
	Terrain.GRASS: preload("res://assets/tiles/terrain_grass_block_top.png"),
	Terrain.DIRT: preload("res://assets/tiles/terrain_dirt_block_top.png"),
	Terrain.STONE: preload("res://assets/tiles/terrain_stone_block_top.png"),
}
const TEX_FILL := {
	Terrain.GRASS: preload("res://assets/tiles/terrain_grass_block.png"),
	Terrain.DIRT: preload("res://assets/tiles/terrain_dirt_block.png"),
	Terrain.STONE: preload("res://assets/tiles/terrain_stone_block.png"),
}

@export var tiles_x: int = 4
@export var tiles_y: int = 1
@export var terrain: Terrain = Terrain.GRASS


func _ready() -> void:
	_build()


func _build() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tiles_x * TILE, tiles_y * TILE)
	var collision := $CollisionShape2D
	collision.shape = shape
	collision.position = shape.size * 0.5

	var top: Texture2D = TEX_TOP[terrain]
	var fill: Texture2D = TEX_FILL[terrain]
	for y in tiles_y:
		for x in tiles_x:
			var sprite := Sprite2D.new()
			sprite.texture = top if y == 0 else fill
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(x * TILE, y * TILE)
			add_child(sprite)
