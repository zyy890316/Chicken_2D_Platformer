extends Area2D

const TEX_OFF := preload("res://assets/tiles/flag_off.png")
const TEX_A := preload("res://assets/tiles/flag_green_a.png")
const TEX_B := preload("res://assets/tiles/flag_green_b.png")

@export var index: int = 1
@export var start_active: bool = false

var _active := false
var _wave_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var spawn: Marker2D = $Spawn


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	GameState.level_reset.connect(_sync_from_state)
	_sync_from_state()
	body_entered.connect(_on_body_entered)


func _sync_from_state() -> void:
	_set_active(start_active or index <= GameState.checkpoint_index)


func _process(delta: float) -> void:
	if not _active:
		return
	_wave_time += delta
	sprite.texture = TEX_A if int(_wave_time * 4.0) % 2 == 0 else TEX_B


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.activate_checkpoint(index, spawn.global_position):
		_set_active(true)


func _set_active(value: bool) -> void:
	_active = value
	if _active:
		sprite.texture = TEX_A
	else:
		_wave_time = 0.0
		sprite.texture = TEX_OFF
