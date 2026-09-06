extends Node2D

const TILE := 64
const PlatformScene := preload("res://scenes/platform.tscn")
const PlayerScene := preload("res://scenes/player.tscn")
const WaterScene := preload("res://scenes/water.tscn")
const CheckpointScene := preload("res://scenes/checkpoint.tscn")
const HouseScene := preload("res://scenes/goal_house.tscn")
const BG_TEX := preload("res://assets/tiles/background_color_trees.png")

@onready var food_label: Label = $UI/FoodLabel
@onready var hint_label: Label = $UI/Hint
@onready var win_panel: ColorRect = $UI/WinPanel
@onready var win_score: Label = $UI/WinPanel/Center/Panel/VBox/Score

var _can_restart := false


func _ready() -> void:
	_add_background()
	_build_mountain()
	var spawn := _tile(5, 40) + Vector2(0, -36)
	var player: CharacterBody2D = PlayerScene.instantiate()
	player.position = spawn
	player.kill_y = 49 * TILE
	add_child(player)
	_limit_camera(player)
	GameState.reset_for_level(spawn)
	GameState.won.connect(_on_won)
	GameState.checkpoint_reached.connect(_on_checkpoint)
	food_label.text = "Food: 0"
	win_panel.visible = false


func _process(_delta: float) -> void:
	food_label.text = "Food: %d" % GameState.food_score
	if _can_restart and GameState.is_won and (
		Input.is_action_just_pressed("restart")
		or Input.is_action_just_pressed("jump")
	):
		GameState.restart_level()


func _build_mountain() -> void:
	_add_water(-2, 41, 40, 8)

	# Foot of the mountain: walk, jump, double jump.
	_add_platform(1, 40, 14, 5, GrassPlatform.Terrain.GRASS)
	_add_checkpoint(3, 40, 0, true)
	_add_platform(17, 40, 6, 5, GrassPlatform.Terrain.GRASS)
	_add_platform(27, 40, 8, 5, GrassPlatform.Terrain.GRASS)
	_add_checkpoint(29, 40, 1)

	# Climb left. Temporary platforms stand in for later tree puzzles.
	_add_platform(22, 37, 3, 1, GrassPlatform.Terrain.GRASS)
	_add_platform(16, 34, 4, 1, GrassPlatform.Terrain.GRASS)
	_add_platform(8, 31, 4, 1, GrassPlatform.Terrain.DIRT)
	_add_platform(1, 28, 11, 3, GrassPlatform.Terrain.DIRT)
	_add_checkpoint(3, 28, 2)
	_add_platform(13, 28, 3, 1, GrassPlatform.Terrain.DIRT, "temp_tree_bridge")
	_add_platform(18, 28, 10, 3, GrassPlatform.Terrain.DIRT)

	_add_platform(25, 25, 3, 1, GrassPlatform.Terrain.DIRT)
	_add_platform(19, 22, 3, 1, GrassPlatform.Terrain.STONE)
	_add_platform(16, 20, 2, 1, GrassPlatform.Terrain.STONE, "temp_tree_stairs")
	_add_platform(13, 18, 2, 1, GrassPlatform.Terrain.STONE, "temp_tree_stairs")
	_add_platform(10, 16, 2, 1, GrassPlatform.Terrain.STONE, "temp_tree_stairs")
	_add_platform(1, 15, 10, 3, GrassPlatform.Terrain.STONE)
	_add_checkpoint(3, 15, 3)

	# Mix stretch to the friend's house.
	_add_platform(13, 12, 3, 1, GrassPlatform.Terrain.STONE)
	_add_platform(19, 9, 4, 1, GrassPlatform.Terrain.STONE)
	_add_platform(14, 6, 3, 1, GrassPlatform.Terrain.STONE)
	_add_platform(20, 3, 12, 4, GrassPlatform.Terrain.STONE)
	_add_house(27, 3)


func _add_background() -> void:
	var parallax := Parallax2D.new()
	parallax.repeat_size = Vector2(256, 256)
	parallax.scroll_scale = Vector2(0.25, 0.18)
	parallax.z_index = -8
	var sprite := Sprite2D.new()
	sprite.texture = BG_TEX
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parallax.add_child(sprite)
	add_child(parallax)


func _add_platform(tx: int, ty: int, w: int, h: int, terrain: GrassPlatform.Terrain, extra_group: String = "") -> void:
	var platform := PlatformScene.instantiate() as GrassPlatform
	platform.position = _tile(tx, ty)
	platform.tiles_x = w
	platform.tiles_y = h
	platform.terrain = terrain
	if extra_group != "":
		platform.add_to_group(extra_group)
	add_child(platform)


func _add_water(tx: int, ty: int, w: int, h: int) -> void:
	var water := WaterScene.instantiate()
	water.position = _tile(tx, ty)
	water.tiles_x = w
	water.tiles_y = h
	add_child(water)


func _add_checkpoint(tx: int, ty: int, index: int, start_active: bool = false) -> void:
	var flag := CheckpointScene.instantiate()
	flag.position = _tile(tx, ty) + Vector2(0, -TILE)
	flag.index = index
	flag.start_active = start_active
	add_child(flag)


func _add_house(tx: int, ty: int) -> void:
	var house := HouseScene.instantiate()
	house.position = _tile(tx, ty)
	add_child(house)


func _limit_camera(player: Node) -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_right = 36 * TILE
	camera.limit_top = -2 * TILE
	camera.limit_bottom = 48 * TILE
	camera.limit_smoothed = true


func _tile(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE, ty * TILE)


func _on_checkpoint(index: int) -> void:
	hint_label.text = "Checkpoint %d saved!" % index
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_callback(func() -> void:
		hint_label.text = "Climb to your friend's house. Don't fall in the water."
	)


func _on_won() -> void:
	win_score.text = "Food: %d" % GameState.food_score
	win_panel.visible = true
	hint_label.text = ""
	await get_tree().create_timer(0.5).timeout
	_can_restart = true
