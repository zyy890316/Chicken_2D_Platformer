extends Node

const BGM_PATHS := [
	"res://assets/audio/bgm.ogg",
	"res://assets/audio/bgm.mp3",
	"res://assets/audio/bgm.wav",
]

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = -10.0
	add_child(_player)
	_start()


func _start() -> void:
	var path := _find_bgm()
	if path == "":
		push_warning("No BGM yet. Put the Suno download at res://assets/audio/bgm.mp3")
		return
	var stream := load(path)
	if stream == null:
		push_warning("Could not load BGM at %s" % path)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_player.stream = stream
	_player.play()


func _find_bgm() -> String:
	for path in BGM_PATHS:
		if ResourceLoader.exists(path):
			return path
	return ""
