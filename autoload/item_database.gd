extends Node

const ITEMS_JSON: String = "res://data/items.json"

var _items: Dictionary = {}


func _ready() -> void:
	_load_items()


func _load_items() -> void:
	var file := FileAccess.open(ITEMS_JSON, FileAccess.READ)
	if file == null:
		push_error("Failed to open items data: ", ITEMS_JSON)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("Failed to parse items data")
		return
	var data: Dictionary = json.data
	var items_array: Array = data.get("items", [])
	for item_dict in items_array:
		var item := _create_item(item_dict)
		if item != null:
			_items[item.id] = item


func _create_item(dict: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = dict.get("id", "")
	item.name = dict.get("name", "")
	item.description = dict.get("description", "")
	item.icon_path = dict.get("icon_path", "")
	item.max_stack = dict.get("max_stack", 1)
	item.is_key = dict.get("is_key", false)
	item.is_secondary_weapon = dict.get("is_secondary_weapon", false)
	return item


func get_item(id: String) -> ItemData:
	return _items.get(id)
