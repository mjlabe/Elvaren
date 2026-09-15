class_name ItemPickup
extends Area2D

@export var item_id: String


func _ready() -> void:
	if PlayerData.has_item(item_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var item := ItemDatabase.get_item(item_id)
	if item != null:
		PlayerData.add_item(item)
		GameState.set_flag("item_" + item_id + "_collected", true)
	queue_free()
