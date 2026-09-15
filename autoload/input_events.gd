extends Node

const DEADZONE: float = 0.15

func _ready() -> void:
	_register_direction("move_left", KEY_A, JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_register_direction("move_right", KEY_D, JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_register_direction("move_up", KEY_W, JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_register_direction("move_down", KEY_S, JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)

	_register_action("action", KEY_Z, JOY_BUTTON_A)
	_register_action("attack", KEY_X, JOY_BUTTON_X)
	_register_action("item", KEY_C, JOY_BUTTON_B)
	_register_action("roll", KEY_V, JOY_BUTTON_RIGHT_SHOULDER)
	_register_action("menu", KEY_ESCAPE, JOY_BUTTON_START)
	_register_action("start", KEY_ENTER, JOY_BUTTON_START)


func _register_action(action_name: String, key: int, joypad_button: int = -1) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, DEADZONE)
	_add_key(action_name, key)
	if joypad_button != -1:
		_add_joypad_button(action_name, joypad_button)


func _register_direction(action_name: String, key: int, dpad_button: int = -1, axis: int = -1, axis_sign: float = 0.0) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, DEADZONE)
	_add_key(action_name, key)
	if dpad_button != -1:
		_add_joypad_button(action_name, dpad_button)
	if axis != -1:
		_add_joypad_motion(action_name, axis, axis_sign)


func _add_key(action_name: String, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	InputMap.action_add_event(action_name, ev)


func _add_joypad_button(action_name: String, button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action_name, ev)


func _add_joypad_motion(action_name: String, axis: int, sign: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = sign
	InputMap.action_add_event(action_name, ev)


func get_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down", DEADZONE)


func is_attack_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack")


func is_item_just_pressed() -> bool:
	return Input.is_action_just_pressed("item")


func is_roll_just_pressed() -> bool:
	return Input.is_action_just_pressed("roll")


func is_action_just_pressed() -> bool:
	return Input.is_action_just_pressed("action")


func is_menu_just_pressed() -> bool:
	return Input.is_action_just_pressed("menu")
