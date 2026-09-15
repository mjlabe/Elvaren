class_name Maiden
extends Area2D

@export var crystal_id: String


func _ready() -> void:
	if GameState.get_flag("crystal_" + crystal_id + "_collected"):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not crystal_id.is_empty():
		GameState.collect_crystal(crystal_id)
	set_deferred("monitoring", false)
	DialogManager.show_dialog([
		{"speaker": "Maiden", "text": "Thank you, hero! Take this crystal and save the next kingdom."}
	])
	SaveManager.save_game()
