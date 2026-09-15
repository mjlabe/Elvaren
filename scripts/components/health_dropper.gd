class_name HealthDropper
extends Node

@export_range(0.0, 1.0, 0.01) var drop_chance: float = 0.25
@export var pickup_scene: PackedScene

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()


func try_drop(drop_position: Vector2, drop_parent: Node) -> bool:
	if pickup_scene == null or drop_parent == null or _random.randf() >= drop_chance:
		return false
	var pickup := pickup_scene.instantiate() as Node2D
	if pickup == null:
		return false
	if drop_parent is Node2D:
		pickup.position = (drop_parent as Node2D).to_local(drop_position)
	else:
		pickup.position = drop_position
	drop_parent.add_child(pickup)
	return true
