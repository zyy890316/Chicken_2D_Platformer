extends Area2D

const TILE := 64
const TEX_DOOR := preload("res://assets/tiles/door_closed.png")
const TEX_DOOR_TOP := preload("res://assets/tiles/door_closed_top.png")
const TEX_WINDOW := preload("res://assets/tiles/window.png")
const TEX_STONE := preload("res://assets/tiles/terrain_stone_block.png")
const TEX_FRIEND := preload("res://assets/tiles/friend_idle.png")


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 1
	_build()
	body_entered.connect(_on_body_entered)


func _build() -> void:
	# House sits on the platform: 3 tiles wide, 3 tiles tall, growing upward.
	_add_sprite(TEX_STONE, Vector2(0, -3 * TILE))
	_add_sprite(TEX_WINDOW, Vector2(TILE, -3 * TILE))
	_add_sprite(TEX_STONE, Vector2(2 * TILE, -3 * TILE))
	_add_sprite(TEX_STONE, Vector2(0, -2 * TILE))
	_add_sprite(TEX_DOOR_TOP, Vector2(TILE, -2 * TILE))
	_add_sprite(TEX_STONE, Vector2(2 * TILE, -2 * TILE))
	_add_sprite(TEX_STONE, Vector2(0, -TILE))
	_add_sprite(TEX_DOOR, Vector2(TILE, -TILE))
	_add_sprite(TEX_STONE, Vector2(2 * TILE, -TILE))

	var friend := Sprite2D.new()
	friend.texture = TEX_FRIEND
	friend.centered = true
	friend.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	friend.position = Vector2(-28, -40)
	friend.scale = Vector2(0.55, 0.55)
	add_child(friend)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, 2 * TILE)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(TILE + TILE * 0.5, -TILE)


func _add_sprite(texture: Texture2D, pos: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	add_child(sprite)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.win_level()
