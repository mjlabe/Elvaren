extends Control

@onready var start_button: Button = $StartButton
@onready var continue_button: Button = $ContinueButton


func _ready() -> void:
	HUD.visible = false
	start_button.pressed.connect(_on_start)
	continue_button.pressed.connect(_on_continue)

	if SaveManager.has_save():
		continue_button.grab_focus()
	else:
		continue_button.disabled = true
		start_button.grab_focus()


func _on_start() -> void:
	PlayerData.reset_for_new_game()
	SceneManager.change_scene("res://scenes/world/world.tscn")


func _on_continue() -> void:
	if SaveManager.load_game():
		SceneManager.change_scene(PlayerData.current_scene)
