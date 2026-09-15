extends Node2D

const ROOM_SIZE: Vector2 = Vector2(384, 288)
const TILE_SIZE: int = 16
const FLOOR_COLOR: Color = Color("324b3a")
const FLOOR_ALT_COLOR: Color = Color("385440")
const WALL_COLOR: Color = Color("182d25")
const VINE_COLOR: Color = Color("397344")


func _ready() -> void:
	HUD.visible = true
	PlayerData.current_scene = scene_file_path
	if GameState.get_flag("boss_bramble_lord_defeated"):
		$Door.open()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), WALL_COLOR)
	for tile_y in range(1, int(ROOM_SIZE.y / TILE_SIZE) - 1):
		for tile_x in range(1, int(ROOM_SIZE.x / TILE_SIZE) - 1):
			var color := FLOOR_COLOR if (tile_x + tile_y) % 2 == 0 else FLOOR_ALT_COLOR
			draw_rect(Rect2(tile_x * TILE_SIZE, tile_y * TILE_SIZE, TILE_SIZE, TILE_SIZE), color)
	for x in range(TILE_SIZE, int(ROOM_SIZE.x) - TILE_SIZE, TILE_SIZE * 2):
		draw_rect(Rect2(x, 8, 12, 5), VINE_COLOR)
		draw_rect(Rect2(x + TILE_SIZE, ROOM_SIZE.y - 13, 12, 5), VINE_COLOR)
	for y in range(TILE_SIZE, int(ROOM_SIZE.y) - TILE_SIZE, TILE_SIZE * 2):
		draw_rect(Rect2(8, y, 5, 12), VINE_COLOR)
		draw_rect(Rect2(ROOM_SIZE.x - 13, y + TILE_SIZE, 5, 12), VINE_COLOR)
	draw_rect(Rect2(224, 16, 32, ROOM_SIZE.y - 32), Color("26372e"), false, 2.0)
