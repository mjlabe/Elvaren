extends Node

const SAVE_PATH: String = "user://save.json"


func save_game() -> bool:
	var equipped_item_id := ""
	if PlayerData.equipped_item != null:
		equipped_item_id = PlayerData.equipped_item.id
	var data := {
		"version": 1,
		"flags": GameState.flags,
		"health": PlayerData.health,
		"max_health": PlayerData.max_health,
		"inventory": PlayerData.get_inventory_ids(),
		"equipped_item": equipped_item_id,
		"position": [PlayerData.position.x, PlayerData.position.y],
		"world_area": [PlayerData.world_area.x, PlayerData.world_area.y],
		"current_scene": PlayerData.current_scene,
		"timestamp": Time.get_unix_time_from_system()
	}
	var json := JSON.stringify(data, "  ")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: ", SAVE_PATH)
		return false
	file.store_string(json)
	file.close()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var content := FileAccess.get_file_as_string(SAVE_PATH)
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("Failed to parse save file")
		return false
	if not json.data is Dictionary:
		push_error("Save data must be a dictionary")
		return false
	var data: Dictionary = json.data
	GameState.flags = data.get("flags", {})
	PlayerData.max_health = maxi(int(data.get("max_health", PlayerData.max_health)), 1)
	PlayerData.health = clampi(int(data.get("health", PlayerData.max_health)), 0, PlayerData.max_health)
	PlayerData.restore_inventory(data.get("inventory", []), str(data.get("equipped_item", "")))
	var pos: Array = data.get("position", [0.0, 0.0])
	PlayerData.position = Vector2(float(pos[0]), float(pos[1]))
	var area: Array = data.get("world_area", [0, 0])
	PlayerData.world_area = Vector2i(int(area[0]), int(area[1]))
	PlayerData.current_scene = str(data.get("current_scene", ""))
	if PlayerData.current_scene.is_empty() or not ResourceLoader.exists(PlayerData.current_scene, "PackedScene"):
		PlayerData.current_scene = "res://scenes/world/world.tscn"
	PlayerData.health_changed.emit(PlayerData.health, PlayerData.max_health)
	return true
