class_name GrassPlatform
extends StaticBody2D

const TILE := 64

@export var tiles_x: int = 4
@export var tiles_y: int = 1

const TEX_TOP := preload("res://assets/tiles/terrain_grass_block_top.svg")
const TEX_FILL := preload("res://assets/tiles/terrain_grass_block.svg")


func _ready() -> void:
	_build()


func _build() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tiles_x * TILE, tiles_y * TILE)
	var collision := $CollisionShape2D
	collision.shape = shape
	collision.position = shape.size * 0.5

	for y in tiles_y:
		for x in tiles_x:
			var sprite := Sprite2D.new()
			sprite.texture = TEX_TOP if y == 0 else TEX_FILL
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(x * TILE, y * TILE)
			add_child(sprite)
