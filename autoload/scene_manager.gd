extends Node

var _current_scene: Node = null


func _ready() -> void:
	var root := get_tree().root
	_current_scene = root.get_child(root.get_child_count() - 1)


func change_scene(path: String) -> void:
	call_deferred("_deferred_change_scene", path)


func _deferred_change_scene(path: String) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("Failed to load scene: ", path)
		return
	if _current_scene != null:
		_current_scene.free()
	_current_scene = scene.instantiate()
	get_tree().root.add_child(_current_scene)
	get_tree().current_scene = _current_scene
	_restore_player_position()


func _restore_player_position() -> void:
	if PlayerData.position == Vector2.ZERO:
		return
	var players := _current_scene.get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0] as Player
	if player == null:
		return
	player.global_position = PlayerData.position
