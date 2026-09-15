class_name DungeonEntrance
extends Area2D

@export_file("*.tscn") var destination_path: String = "res://scenes/dungeons/thornveil_room_1.tscn"
@export var destination_position: Vector2 = Vector2.ZERO

var _entered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _entered or not body.is_in_group("player") or not ResourceLoader.exists(destination_path, "PackedScene"):
		return
	_entered = true
	set_deferred("monitoring", false)
	PlayerData.position = destination_position
	SceneManager.change_scene(destination_path)
