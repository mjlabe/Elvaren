extends Node

signal dialog_finished
signal line_changed(speaker: String, text: String)
signal visibility_changed(visible: bool)

var _queue: Array[Dictionary] = []
var _active: bool = false


func show_dialog(lines: Array[Dictionary]) -> void:
	_queue = lines.duplicate()
	_active = true
	visibility_changed.emit(true)
	_advance()


func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	if _queue.is_empty():
		_active = false
		visibility_changed.emit(false)
		dialog_finished.emit()
		return
	var line: Dictionary = _queue.pop_front()
	line_changed.emit(str(line.get("speaker", "")), str(line.get("text", "")))


func is_active() -> bool:
	return _active
