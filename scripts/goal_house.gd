extends Area2D

const TILE := 64
const TEX_HOUSE := preload("res://assets/game/house.png")
const TEX_FRIEND := preload("res://assets/game/hedgehog.png")
const HOUSE_HEIGHT := 200.0
const FRIEND_HEIGHT := 58.0
const GROUND_OVERLAP := 8.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 1
	_build()
	body_entered.connect(_on_body_entered)


func _build() -> void:
	var house_scale := HOUSE_HEIGHT / float(TEX_HOUSE.get_height())
	var house_w := float(TEX_HOUSE.get_width()) * house_scale

	var house := Sprite2D.new()
	house.texture = TEX_HOUSE
	house.centered = false
	house.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	house.scale = Vector2(house_scale, house_scale)
	house.position = Vector2(0, -HOUSE_HEIGHT + GROUND_OVERLAP)
	add_child(house)

	var friend := Sprite2D.new()
	friend.name = "Friend"
	friend.texture = TEX_FRIEND
	friend.centered = true
	friend.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var friend_scale := FRIEND_HEIGHT / float(TEX_FRIEND.get_height())
	friend.scale = Vector2(friend_scale, friend_scale)
	friend.z_index = 1
	friend.position = Vector2(-36, -FRIEND_HEIGHT * 0.5)
	friend.add_to_group("friend")
	add_child(friend)

	var extra_left := 64.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(house_w + extra_left, TILE * 1.5)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position = Vector2(house_w * 0.5 - extra_left * 0.5, -TILE * 0.75)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.win_level()
