extends Node

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	add_child(_sfx_player)


func play_music(stream: AudioStream) -> void:
	_music_player.stream = stream
	_music_player.play()


func play_sfx(stream: AudioStream) -> void:
	_sfx_player.stream = stream
	_sfx_player.play()
