extends Node2D

const TILE := 64
const PlatformScene := preload("res://scenes/platform.tscn")
const PlayerScene := preload("res://scenes/player.tscn")
const WaterScene := preload("res://scenes/water.tscn")
const CheckpointScene := preload("res://scenes/checkpoint.tscn")
const HouseScene := preload("res://scenes/goal_house.tscn")
const PlantScene := preload("res://scenes/fruit_plant.tscn")
const FruitPlantScript := preload("res://scripts/fruit_plant.gd")
const BG_TREES := preload("res://assets/tiles/bg_color_trees.png")
const BG_CLOUDS := preload("res://assets/tiles/bg_clouds.png")
const JumpRoutes := preload("res://scripts/jump_route_validator.gd")

@onready var food_label: Label = $UI/FoodLabel
@onready var hint_label: Label = $UI/Hint
@onready var win_panel: ColorRect = $UI/WinPanel
@onready var win_score: Label = $UI/WinPanel/Center/Panel/VBox/Score

var _can_restart := false


func _ready() -> void:
	var spawn := _tile(5, 40) + Vector2(0, -36)
	# Autoload keeps last-run checkpoint_index across reload_current_scene.
	# Reset before flags enter the tree so they do not all unfurl.
	GameState.reset_for_level(spawn)
	_add_background()
	_build_mountain()
	var player: CharacterBody2D = PlayerScene.instantiate()
	player.position = spawn
	player.kill_y = 49 * TILE
	add_child(player)
	_limit_camera(player)
	GameState.won.connect(_on_won)
	GameState.checkpoint_reached.connect(_on_checkpoint)
	food_label.text = "Food: %d/%d" % [GameState.food_score, GameState.food_total]
	win_panel.visible = false


func _process(_delta: float) -> void:
	food_label.text = "Food: %d/%d" % [GameState.food_score, GameState.food_total]
	if _can_restart and GameState.is_won and (
		Input.is_action_just_pressed("restart")
		or Input.is_action_just_pressed("jump")
	):
		GameState.restart_level()


func _build_mountain() -> void:
	_add_water(-2, 41, 54, 8)

	# Spec: id, tx, ty, w, h, terrain, group. Path is the intended route.
	# Same data is built and fed to JumpRouteValidator (ceiling / gap checks).
	# 2-tile stairs go the same way; reverse only with a 3-tile double jump, or
	# after 6 tiles of rise, so the ledge 4 tiles up never covers the takeoff.
	var grass := GrassPlatform.Terrain.GRASS
	var dirt := GrassPlatform.Terrain.DIRT
	var stone := GrassPlatform.Terrain.STONE
	var specs: Array = [
		{id = "g0", tx = 1, ty = 40, w = 12, h = 5, t = grass, g = ""},
		{id = "g1", tx = 15, ty = 40, w = 5, h = 5, t = grass, g = ""},
		{id = "g2", tx = 23, ty = 40, w = 12, h = 5, t = grass, g = ""},
		{id = "c1", tx = 30, ty = 38, w = 5, h = 1, t = grass, g = ""},
		{id = "c2", tx = 35, ty = 36, w = 5, h = 1, t = grass, g = ""},
		{id = "c3", tx = 30, ty = 33, w = 6, h = 1, t = grass, g = ""},
		{id = "c4", tx = 24, ty = 31, w = 7, h = 1, t = grass, g = ""},
		{id = "d0", tx = 1, ty = 29, w = 24, h = 1, t = dirt, g = ""},
		{id = "br", tx = 26, ty = 29, w = 3, h = 1, t = dirt, g = "temp_tree_bridge"},
		{id = "u1", tx = 29, ty = 27, w = 6, h = 1, t = dirt, g = ""},
		{id = "u2", tx = 34, ty = 25, w = 6, h = 1, t = stone, g = ""},
		{id = "s1", tx = 39, ty = 23, w = 6, h = 1, t = stone, g = ""},
		{id = "s2", tx = 41, ty = 21, w = 6, h = 1, t = stone, g = ""},
		{id = "s3", tx = 32, ty = 19, w = 7, h = 1, t = stone, g = ""},
		{id = "s4", tx = 27, ty = 17, w = 6, h = 1, t = stone, g = "temp_tree_stairs"},
		{id = "s5", tx = 22, ty = 15, w = 6, h = 1, t = stone, g = "temp_tree_stairs"},
		{id = "s6", tx = 16, ty = 13, w = 7, h = 1, t = stone, g = "temp_tree_stairs"},
		{id = "s7", tx = 22, ty = 10, w = 7, h = 1, t = stone, g = ""},
		{id = "s8", tx = 28, ty = 8, w = 7, h = 1, t = stone, g = ""},
		{id = "s9", tx = 34, ty = 6, w = 7, h = 1, t = stone, g = ""},
		{id = "top", tx = 40, ty = 4, w = 8, h = 1, t = stone, g = ""},
	]
	var path: Array = [
		"g0", "g1", "g2", "c1", "c2", "c3", "c4", "d0", "br",
		"u1", "u2", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "top",
	]

	for spec in specs:
		_add_platform(spec.tx, spec.ty, spec.w, spec.h, spec.t, spec.g)

	_add_checkpoint(3, 40, 0, true)
	_add_checkpoint(26, 40, 1)
	_add_checkpoint(3, 29, 2)
	_add_checkpoint(17, 13, 3)
	_add_house(42, 4)

	var plants: Array = [
		{id = "bush_start", kind = FruitPlantScript.Kind.BUSH, tx = 8.0, ty = 40},
		{id = "tree_start", kind = FruitPlantScript.Kind.TREE, tx = 10.0, ty = 40},
		{id = "tree_g2", kind = FruitPlantScript.Kind.TREE, tx = 32.0, ty = 40},
		{id = "bush_d0", kind = FruitPlantScript.Kind.BUSH, tx = 10.0, ty = 29},
		{id = "tree_d0", kind = FruitPlantScript.Kind.TREE, tx = 18.0, ty = 29},
		{id = "tree_s3", kind = FruitPlantScript.Kind.TREE, tx = 35.0, ty = 19},
		{id = "bush_s6", kind = FruitPlantScript.Kind.BUSH, tx = 20.0, ty = 13},
		{id = "bush_s8", kind = FruitPlantScript.Kind.BUSH, tx = 30.0, ty = 8},
	]
	for plant in plants:
		if plant.kind == FruitPlantScript.Kind.TREE:
			plant.tx = JumpRoutes.nudge_tree(plant.tx, plant.ty, specs)
		_add_plant(plant.id, plant.kind, plant.tx, plant.ty)
	GameState.food_total = plants.size()

	var errors := JumpRoutes.validate_path(specs, path)
	if errors.is_empty():
		print("Jump routes OK (%d hops)" % (path.size() - 1))
	else:
		for err in errors:
			push_warning("Jump route: " + err)


func _add_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)

	var sky := ColorRect.new()
	sky.color = Color(0.62, 0.84, 0.96, 1)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sky)

	var trees := TextureRect.new()
	trees.texture = BG_TREES
	trees.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trees.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	trees.set_anchors_preset(Control.PRESET_FULL_RECT)
	trees.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(trees)

	var clouds := TextureRect.new()
	clouds.texture = BG_CLOUDS
	clouds.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clouds.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	clouds.modulate = Color(1, 1, 1, 0.45)
	clouds.set_anchors_preset(Control.PRESET_FULL_RECT)
	clouds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(clouds)


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


func _add_plant(plant_id: String, kind: int, tx: float, ty: int) -> void:
	var plant := PlantScene.instantiate()
	plant.plant_id = plant_id
	plant.kind = kind
	plant.position = Vector2((tx + 0.5) * TILE, ty * TILE)
	add_child(plant)


func _limit_camera(player: Node) -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_right = 52 * TILE
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
		hint_label.text = "Jump through trees or walk through bushes for food."
	)


func _on_won() -> void:
	win_score.text = "Food: %d/%d" % [GameState.food_score, GameState.food_total]
	win_panel.visible = true
	hint_label.text = ""
	await get_tree().create_timer(0.5).timeout
	_can_restart = true
