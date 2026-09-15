extends CanvasLayer

@onready var hearts_container: HBoxContainer = $HeartsContainer
@onready var item_label: Label = $ItemLabel
@onready var area_label: Label = $AreaLabel
@onready var dialog_panel: Panel = $DialogPanel
@onready var speaker_label: Label = $DialogPanel/SpeakerLabel
@onready var dialog_label: Label = $DialogPanel/DialogLabel
@onready var map_panel: Panel = $MapPanel
@onready var map_grid: GridContainer = $MapPanel/MapGrid

var _map_coords: Vector2i = Vector2i.ZERO
var _map_size: Vector2i = Vector2i(8, 8)


func _ready() -> void:
	PlayerData.health_changed.connect(_on_health_changed)
	PlayerData.item_equipped.connect(_on_item_equipped)
	DialogManager.line_changed.connect(_on_dialog_line_changed)
	DialogManager.visibility_changed.connect(_on_dialog_visibility_changed)
	_update_hearts(PlayerData.health, PlayerData.max_health)
	_on_item_equipped(PlayerData.equipped_item)
	dialog_panel.visible = DialogManager.is_active()
	_build_map_grid()


func _on_health_changed(health: int, max_health: int) -> void:
	_update_hearts(health, max_health)


func _on_item_equipped(item: ItemData) -> void:
	item_label.text = "B: --" if item == null else "B: " + item.name


func _on_dialog_line_changed(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	dialog_label.text = text


func _on_dialog_visibility_changed(visible: bool) -> void:
	dialog_panel.visible = visible


func show_area_name(area_name: String, coords: Vector2i, map_size: Vector2i) -> void:
	area_label.text = "%s\nMAP %d,%d / %d×%d" % [area_name, coords.x + 1, coords.y + 1, map_size.x, map_size.y]
	_map_coords = coords
	_map_size = map_size
	_update_map_grid()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("menu") and not DialogManager.is_active():
		map_panel.visible = not map_panel.visible
		get_viewport().set_input_as_handled()


func _build_map_grid() -> void:
	for index in range(64):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(8, 8)
		map_grid.add_child(cell)
	_update_map_grid()


func _update_map_grid() -> void:
	var cells := map_grid.get_children()
	for y in range(_map_size.y):
		for x in range(_map_size.x):
			var index := y * _map_size.x + x
			if index >= cells.size():
				continue
			var cell := cells[index] as ColorRect
			var coords := Vector2i(x, y)
			if coords == _map_coords:
				cell.color = Color("f0d66c")
			elif GameState.get_flag("visited_%d_%d" % [x, y]):
				cell.color = Color("4f8f43")
			else:
				cell.color = Color("26352c")


func _update_hearts(health: int, max_health: int) -> void:
	for child in hearts_container.get_children():
		child.queue_free()
	var units := PlayerData.UNITS_PER_HEART
	var full_hearts := health / units
	var partial := health % units
	var total_hearts := max_health / units
	for index in range(total_hearts):
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(8, 8)
		if index < full_hearts:
			heart.color = Color("e83b3b")
		elif index == full_hearts and partial > 0:
			heart.color = Color("e8893b")
		else:
			heart.color = Color("4a4a4a")
		hearts_container.add_child(heart)
