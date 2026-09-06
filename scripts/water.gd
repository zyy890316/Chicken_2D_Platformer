extends Area2D

const TILE := 64
const TEX_TOP := preload("res://assets/tiles/water_top.png")
const TEX_TOP_LOW := preload("res://assets/tiles/water_top_low.png")
const TEX_FILL := preload("res://assets/tiles/water.png")

@export var tiles_x: int = 8
@export var tiles_y: int = 3

var _top_sprites: Array[Sprite2D] = []
var _wave_time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = -2
	_build()
	body_entered.connect(_on_body_entered)


func _build() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tiles_x * TILE, tiles_y * TILE)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = shape.size * 0.5

	for y in tiles_y:
		for x in tiles_x:
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.position = Vector2(x * TILE, y * TILE)
			if y == 0:
				sprite.texture = TEX_TOP
				_top_sprites.append(sprite)
			else:
				sprite.texture = TEX_FILL
			add_child(sprite)


func _process(delta: float) -> void:
	_wave_time += delta
	var use_low := int(_wave_time * 3.0) % 2 == 0
	for sprite in _top_sprites:
		sprite.texture = TEX_TOP_LOW if use_low else TEX_TOP


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("can_take_hazard") and body.can_take_hazard():
		GameState.kill_player()
