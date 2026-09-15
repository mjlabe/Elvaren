class_name AreaExit
extends Area2D


@export var direction: Vector2i
@export var enabled: bool = true


signal player_exited(direction: Vector2i)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not enabled:
		return
	if body.is_in_group("player"):
		enabled = false
		set_deferred("monitoring", false)
		player_exited.emit(direction)
