class_name DungeonEntrance
extends Area2D

@export var destination_scene: PackedScene = preload("res://scenes/dungeons/thornveil_room_1.tscn")
@export var destination_position: Vector2 = Vector2.ZERO

var _entered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _entered or not body.is_in_group("player") or destination_scene == null:
		return
	_entered = true
	PlayerData.position = destination_position
	SceneManager.change_scene(destination_scene.resource_path)
