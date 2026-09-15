class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State = null
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
	if initial_state:
		_change_state(initial_state)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _change_state(new_state: State) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	if current_state:
		current_state.enter()


func change_state(state_name: String) -> void:
	if states.has(state_name):
		_change_state(states[state_name])
