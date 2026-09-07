extends Node

signal died
signal won
signal checkpoint_reached(index: int)
signal level_reset
signal plants_restored

var checkpoint_index := 0
var checkpoint_position := Vector2.ZERO
var food_score := 0
var is_won := false
var _busy := false
var _collected: Dictionary = {}
var _snapshot_food := 0
var _snapshot_collected: Dictionary = {}


func reset_for_level(spawn_position: Vector2) -> void:
	checkpoint_index = 0
	checkpoint_position = spawn_position
	food_score = 0
	is_won = false
	_busy = false
	_collected.clear()
	_snapshot_food = 0
	_snapshot_collected.clear()
	level_reset.emit()


func activate_checkpoint(index: int, spawn_position: Vector2) -> bool:
	if index <= checkpoint_index:
		return false
	checkpoint_index = index
	checkpoint_position = spawn_position
	_snapshot_food = food_score
	_snapshot_collected = _collected.duplicate()
	checkpoint_reached.emit(index)
	return true


func collect_food(plant_id: String, amount: int = 1) -> bool:
	if plant_id == "" or is_won or _collected.has(plant_id):
		return false
	_collected[plant_id] = true
	food_score += amount
	return true


func is_plant_collected(plant_id: String) -> bool:
	return _collected.has(plant_id)


func kill_player() -> void:
	if is_won or _busy:
		return
	_busy = true
	var player := get_player()
	if player != null:
		player.begin_death()
	died.emit()
	await get_tree().create_timer(0.4).timeout
	food_score = _snapshot_food
	_collected = _snapshot_collected.duplicate()
	plants_restored.emit()
	player = get_player()
	if player != null:
		player.respawn(checkpoint_position)
	_busy = false


func win_level() -> void:
	if is_won or _busy:
		return
	is_won = true
	var player := get_player()
	if player != null:
		player.control_enabled = false
		player.velocity = Vector2.ZERO
	won.emit()


func restart_level() -> void:
	reset_for_level(checkpoint_position)
	get_tree().reload_current_scene()


func get_player() -> CharacterBody2D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0]
