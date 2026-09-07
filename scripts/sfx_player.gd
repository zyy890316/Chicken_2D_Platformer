extends Node

const JUMP := preload("res://assets/audio/sfx_jump.wav")
const FLUTTER := preload("res://assets/audio/sfx_flutter.wav")
const PICKUP := preload("res://assets/audio/sfx_pickup.wav")

var _jump: AudioStreamPlayer
var _flutter: AudioStreamPlayer
var _pickup: AudioStreamPlayer


func _ready() -> void:
	_jump = _make_player(JUMP, -6.0)
	_flutter = _make_player(FLUTTER, -5.0)
	_pickup = _make_player(PICKUP, -4.0)


func play_jump(is_double: bool = false) -> void:
	var player := _flutter if is_double else _jump
	if player.playing:
		player.stop()
	player.play()


func play_pickup() -> void:
	if _pickup.playing:
		_pickup.stop()
	_pickup.play()


func _make_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	player.volume_db = volume_db
	add_child(player)
	return player
