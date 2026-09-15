class_name Switch
extends Area2D

signal activated
signal deactivated

@export var is_toggle: bool = true
@export var is_oneshot: bool = false

var _active: bool = false
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not _can_trigger():
		return
	if body.is_in_group("player") and not is_oneshot:
		_toggle()


func _can_trigger() -> bool:
	if is_oneshot and _triggered:
		return false
	return true


func _toggle() -> void:
	if is_oneshot:
		_triggered = true
	_active = not _active
	if _active:
		activated.emit()
		modulate = Color(0.2, 1.0, 0.2, 1.0)
	else:
		deactivated.emit()
		modulate = Color(1.0, 0.2, 0.2, 1.0)


func trigger() -> void:
	if _can_trigger():
		_toggle()
