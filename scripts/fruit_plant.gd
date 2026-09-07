class_name FruitPlant
extends Area2D

enum Kind { TREE, BUSH }

const TEX_FRUIT := {
	Kind.TREE: preload("res://assets/game/tree_fruit.png"),
	Kind.BUSH: preload("res://assets/game/bush_fruit.png"),
}
const TEX_EMPTY := {
	Kind.TREE: preload("res://assets/game/tree_empty.png"),
	Kind.BUSH: preload("res://assets/game/bush_empty.png"),
}
const HEIGHT := {
	Kind.TREE: 156.0,
	Kind.BUSH: 52.0,
}
const GROUND_SINK := 12.0

@export var kind: Kind = Kind.TREE
@export var plant_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 0
	_build_visual()
	GameState.level_reset.connect(_sync_from_state)
	GameState.plants_restored.connect(_sync_from_state)
	_sync_from_state()
	body_entered.connect(_on_body_entered)


func _build_visual() -> void:
	var fruit: Texture2D = TEX_FRUIT[kind]
	var plant_h: float = HEIGHT[kind]
	var plant_scale := plant_h / float(fruit.get_height())
	sprite.texture = fruit
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2(plant_scale, plant_scale)
	sprite.position = Vector2(0, -plant_h * 0.5 + GROUND_SINK)

	var shape := RectangleShape2D.new()
	if kind == Kind.TREE:
		shape.size = Vector2(fruit.get_width() * plant_scale * 0.72, plant_h * 0.55)
		collision.position = Vector2(0, -plant_h * 0.70 + GROUND_SINK)
	else:
		shape.size = Vector2(fruit.get_width() * plant_scale * 0.88, plant_h * 0.82)
		collision.position = Vector2(0, -plant_h * 0.48 + GROUND_SINK)
	collision.shape = shape


func _sync_from_state() -> void:
	var picked := GameState.is_plant_collected(plant_id)
	sprite.texture = TEX_EMPTY[kind] if picked else TEX_FRUIT[kind]
	monitoring = not picked and not GameState.is_won


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.collect_food(plant_id):
		_sync_from_state()
