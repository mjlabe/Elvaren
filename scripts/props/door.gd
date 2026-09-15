class_name Door
extends StaticBody2D

@export var is_open: bool = false

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_update()


func open() -> void:
	is_open = true
	_update()


func close() -> void:
	is_open = false
	_update()


func _update() -> void:
	visible = not is_open
	if _collision_shape != null:
		_collision_shape.disabled = is_open
