extends Node

const MAX_HEARTS_BASE: int = 3
const UNITS_PER_HEART: int = 4

var max_health: int = MAX_HEARTS_BASE * UNITS_PER_HEART
var health: int = max_health
var inventory: Array[ItemData] = []
var equipped_item: ItemData = null
var position: Vector2 = Vector2.ZERO
var current_scene: String = ""
var world_area: Vector2i = Vector2i.ZERO

signal health_changed(new_health: int, max_health: int)
signal item_equipped(item: ItemData)


func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	health_changed.emit(health, max_health)


func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health, max_health)


func add_item(item: ItemData) -> void:
	if item == null or has_item(item.id):
		return
	inventory.append(item)
	if equipped_item == null and item.is_secondary_weapon:
		equip_item(item)


func equip_item(item: ItemData) -> void:
	if item == null or not has_item(item.id):
		return
	equipped_item = item
	item_equipped.emit(item)


func has_item(item_id: String) -> bool:
	for item in inventory:
		if item.id == item_id:
			return true
	return false


func get_inventory_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in inventory:
		ids.append(item.id)
	return ids


func restore_inventory(item_ids: Array, equipped_item_id: String) -> void:
	inventory.clear()
	equipped_item = null
	for item_id in item_ids:
		var item := ItemDatabase.get_item(str(item_id))
		if item != null:
			inventory.append(item)
	if not equipped_item_id.is_empty():
		equip_item(ItemDatabase.get_item(equipped_item_id))


func reset_for_new_game() -> void:
	max_health = MAX_HEARTS_BASE * UNITS_PER_HEART
	health = max_health
	inventory.clear()
	equipped_item = null
	position = Vector2.ZERO
	current_scene = ""
	world_area = Vector2i.ZERO
	health_changed.emit(health, max_health)
	GameState.flags.clear()
	item_equipped.emit(equipped_item)
