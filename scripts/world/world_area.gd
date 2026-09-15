class_name WorldArea
extends Node2D

signal transition_requested(to_grid: Vector2i, from_dir: Vector2i)

const SCREEN_SIZE: Vector2 = Vector2(384, 288)
const TILE_SIZE: int = 16
const EXIT_SIZE: float = 64.0
const EDGE_THICKNESS: float = 16.0
const EXIT_ACTIVATION_DELAY: float = 0.05
const GROUND_LIGHTEN: float = 0.035

var grid_position: Vector2i = Vector2i.ZERO
var _area_data: Dictionary = {}
var _exits: Array[AreaExit] = []
var _spawns: Dictionary = {}
var _open_exits: Dictionary = {}


func configure(coords: Vector2i, area_data: Dictionary) -> void:
	grid_position = coords
	_area_data = area_data


func _ready() -> void:
	_gather_nodes(self)
	for area_exit in _exits:
		area_exit.player_exited.connect(_on_player_exited)
	_build_obstacle_collisions()
	_spawn_dungeon()
	_spawn_enemies()
	queue_redraw()


func _draw() -> void:
	var base_color: Color = _area_data.get("base_color", Color("4f8f43"))
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), base_color)
	for tile_y in range(1, int(SCREEN_SIZE.y / TILE_SIZE) - 1):
		for tile_x in range(1, int(SCREEN_SIZE.x / TILE_SIZE) - 1):
			if (tile_x + tile_y) % 2 == 0:
				draw_rect(Rect2(tile_x * TILE_SIZE, tile_y * TILE_SIZE, TILE_SIZE, TILE_SIZE), base_color.lightened(GROUND_LIGHTEN))

	var path_color: Color = _area_data.get("path_color", Color("c9ad68"))
	for path_rect in _area_data.get("paths", []):
		var rect: Rect2 = path_rect
		draw_rect(rect.grow(2.0), path_color.darkened(0.2))
		draw_rect(rect, path_color)
		for x in range(int(rect.position.x) + 8, int(rect.end.x), TILE_SIZE):
			for y in range(int(rect.position.y) + 8, int(rect.end.y), TILE_SIZE):
				draw_rect(Rect2(x, y, 2, 2), path_color.lightened(0.16))

	for water_rect in _area_data.get("waters", []):
		var rect: Rect2 = water_rect
		draw_rect(rect.grow(2.0), Color("244f68"))
		draw_rect(rect, Color("3d86a3"))
		for y in range(int(rect.position.y) + 8, int(rect.end.y), TILE_SIZE):
			draw_line(Vector2(rect.position.x + 6, y), Vector2(rect.end.x - 6, y), Color("66b5c4"), 2.0)

	_draw_edge_terrain()
	for obstacle_data in _area_data.get("obstacles", []):
		_draw_obstacle(obstacle_data)


func _draw_edge_terrain() -> void:
	for x in range(TILE_SIZE / 2, int(SCREEN_SIZE.x), TILE_SIZE):
		if not (_is_open(Vector2i.UP) and absf(x - SCREEN_SIZE.x / 2.0) < EXIT_SIZE / 2.0):
			_draw_edge_feature(Vector2(x, 8))
		if not (_is_open(Vector2i.DOWN) and absf(x - SCREEN_SIZE.x / 2.0) < EXIT_SIZE / 2.0):
			_draw_edge_feature(Vector2(x, SCREEN_SIZE.y - 8))
	for y in range(TILE_SIZE + TILE_SIZE / 2, int(SCREEN_SIZE.y) - TILE_SIZE, TILE_SIZE):
		if not (_is_open(Vector2i.LEFT) and absf(y - SCREEN_SIZE.y / 2.0) < EXIT_SIZE / 2.0):
			_draw_edge_feature(Vector2(8, y))
		if not (_is_open(Vector2i.RIGHT) and absf(y - SCREEN_SIZE.y / 2.0) < EXIT_SIZE / 2.0):
			_draw_edge_feature(Vector2(SCREEN_SIZE.x - 8, y))


func _draw_edge_feature(feature_position: Vector2) -> void:
	match str(_area_data.get("biome", "meadow")):
		"desert", "highland": _draw_rock(feature_position)
		"snow": _draw_pine(feature_position)
		_: _draw_tree(feature_position)


func _draw_obstacle(obstacle_data: Dictionary) -> void:
	var position_value: Vector2 = obstacle_data.get("position", Vector2.ZERO)
	match str(obstacle_data.get("type", "tree")):
		"tree":
			_draw_tree(position_value)
		"rock":
			_draw_rock(position_value)
		"pine":
			_draw_pine(position_value)
		"cactus":
			_draw_cactus(position_value)
		"dead_tree":
			draw_rect(Rect2(position_value + Vector2(-3, -10), Vector2(6, 20)), Color("665039"))
			draw_line(position_value + Vector2(0, -5), position_value + Vector2(-8, -11), Color("665039"), 3.0)
			draw_line(position_value + Vector2(0, -2), position_value + Vector2(8, -8), Color("665039"), 3.0)
		"shrub":
			draw_rect(Rect2(position_value - Vector2(10, 6), Vector2(20, 12)), Color("1f5b35"))
			draw_rect(Rect2(position_value - Vector2(7, 9), Vector2(14, 14)), Color("2f7a3f"))
		"flower":
			draw_rect(Rect2(position_value - Vector2(1, 4), Vector2(2, 8)), Color("286033"))
			draw_circle(position_value - Vector2(0, 5), 3.0, Color("f0d66c"))


func _draw_tree(tree_position: Vector2) -> void:
	draw_rect(Rect2(tree_position + Vector2(-3, 2), Vector2(6, 11)), Color("704523"))
	draw_rect(Rect2(tree_position + Vector2(-10, -7), Vector2(20, 13)), Color("163f2a"))
	draw_rect(Rect2(tree_position + Vector2(-7, -11), Vector2(14, 15)), Color("28663a"))
	draw_rect(Rect2(tree_position + Vector2(-4, -9), Vector2(5, 5)), Color("43834a"))


func _draw_pine(pine_position: Vector2) -> void:
	draw_rect(Rect2(pine_position + Vector2(-2, 2), Vector2(4, 11)), Color("67482f"))
	draw_colored_polygon(PackedVector2Array([pine_position + Vector2(0, -15), pine_position + Vector2(-11, 7), pine_position + Vector2(11, 7)]), Color("285749"))
	draw_colored_polygon(PackedVector2Array([pine_position + Vector2(0, -9), pine_position + Vector2(-9, 10), pine_position + Vector2(9, 10)]), Color("397565"))


func _draw_rock(rock_position: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		rock_position + Vector2(-9, 6), rock_position + Vector2(-7, -5),
		rock_position + Vector2(-2, -9), rock_position + Vector2(7, -6),
		rock_position + Vector2(10, 5), rock_position + Vector2(5, 9),
		rock_position + Vector2(-5, 9)
	]), Color("66706b"))
	draw_line(rock_position + Vector2(-4, -5), rock_position + Vector2(5, -2), Color("9ba49a"), 2.0)


func _draw_cactus(cactus_position: Vector2) -> void:
	draw_rect(Rect2(cactus_position + Vector2(-3, -11), Vector2(6, 22)), Color("327443"))
	draw_rect(Rect2(cactus_position + Vector2(-8, -3), Vector2(7, 5)), Color("327443"))
	draw_rect(Rect2(cactus_position + Vector2(1, 1), Vector2(7, 5)), Color("327443"))
	draw_rect(Rect2(cactus_position + Vector2(-8, -7), Vector2(4, 7)), Color("327443"))
	draw_rect(Rect2(cactus_position + Vector2(4, -3), Vector2(4, 7)), Color("327443"))


func _gather_nodes(node: Node) -> void:
	if node is AreaExit:
		_exits.append(node)
	elif node is Marker2D:
		_spawns[node.name] = node
	for child in node.get_children():
		_gather_nodes(child)


func _build_obstacle_collisions() -> void:
	var obstacles_root := get_node_or_null("Obstacles")
	if obstacles_root == null:
		return
	for obstacle_data in _area_data.get("obstacles", []):
		var obstacle_type := str(obstacle_data.get("type", "tree"))
		if obstacle_type == "flower":
			continue
		var obstacle_position: Vector2 = obstacle_data.get("position", Vector2.ZERO)
		var size := Vector2(20, 20)
		if obstacle_type == "rock":
			size = Vector2(20, 18)
		elif obstacle_type == "shrub":
			size = Vector2(22, 16)
		elif obstacle_type == "pine":
			size = Vector2(20, 22)
		elif obstacle_type == "cactus" or obstacle_type == "dead_tree":
			size = Vector2(18, 22)
		_add_collision_body(obstacles_root, Rect2(obstacle_position - size / 2.0, size))
	for water_rect in _area_data.get("waters", []):
		_add_collision_body(obstacles_root, water_rect)


func _add_collision_body(parent: Node, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size / 2.0
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	collision_shape.shape = rectangle
	body.add_child(collision_shape)
	parent.add_child(body)


func _spawn_dungeon() -> void:
	var dungeon_path := str(_area_data.get("dungeon", ""))
	if dungeon_path.is_empty():
		return
	var dungeon_scene := load(dungeon_path) as PackedScene
	if dungeon_scene == null:
		return
	var entrance := dungeon_scene.instantiate() as Node2D
	if entrance == null:
		return
	entrance.position = _area_data.get("dungeon_position", SCREEN_SIZE / 2.0)
	get_node("Actors").add_child(entrance)


func _spawn_enemies() -> void:
	for enemy_data in _area_data.get("enemies", []):
		var scene_path := str(enemy_data.get("scene", ""))
		var enemy_scene := load(scene_path) as PackedScene
		if enemy_scene == null:
			continue
		var enemy := enemy_scene.instantiate() as Node2D
		if enemy == null:
			continue
		enemy.position = enemy_data.get("position", SCREEN_SIZE / 2.0)
		get_node("Actors").add_child(enemy)


func activate_exits_after_delay() -> void:
	await get_tree().create_timer(EXIT_ACTIVATION_DELAY).timeout
	if not is_inside_tree():
		return
	for area_exit in _exits:
		area_exit.monitoring = area_exit.enabled


func _on_player_exited(direction: Vector2i) -> void:
	transition_requested.emit(grid_position + direction, -direction)


func get_spawn(from_dir: Vector2i) -> Vector2:
	var key := "SpawnDefault"
	match from_dir:
		Vector2i.LEFT: key = "SpawnLeft"
		Vector2i.RIGHT: key = "SpawnRight"
		Vector2i.UP: key = "SpawnTop"
		Vector2i.DOWN: key = "SpawnBottom"
	var marker := _spawns.get(key) as Marker2D
	if marker != null:
		return marker.global_position
	return SCREEN_SIZE / 2.0


func set_exit_and_wall(direction: Vector2i, open: bool) -> void:
	_open_exits[direction] = open
	for area_exit in _exits:
		if area_exit.direction == direction:
			area_exit.enabled = open
	var wall_name := _wall_name(direction)
	var wall := get_node_or_null("Walls/" + wall_name)
	if open and wall != null:
		wall.queue_free()
		_add_open_edge_walls(direction)
	queue_redraw()


func _wall_name(direction: Vector2i) -> String:
	match direction:
		Vector2i.UP: return "WallTop"
		Vector2i.DOWN: return "WallBottom"
		Vector2i.LEFT: return "WallLeft"
		Vector2i.RIGHT: return "WallRight"
	return ""


func _add_open_edge_walls(direction: Vector2i) -> void:
	var walls := get_node("Walls")
	if direction.y != 0:
		var segment_width := (SCREEN_SIZE.x - EXIT_SIZE) / 2.0
		var edge_y := -EDGE_THICKNESS / 2.0 if direction == Vector2i.UP else SCREEN_SIZE.y + EDGE_THICKNESS / 2.0
		_add_collision_body(walls, Rect2(0, edge_y - EDGE_THICKNESS / 2.0, segment_width, EDGE_THICKNESS))
		_add_collision_body(walls, Rect2(SCREEN_SIZE.x - segment_width, edge_y - EDGE_THICKNESS / 2.0, segment_width, EDGE_THICKNESS))
	else:
		var segment_height := (SCREEN_SIZE.y - EXIT_SIZE) / 2.0
		var edge_x := -EDGE_THICKNESS / 2.0 if direction == Vector2i.LEFT else SCREEN_SIZE.x + EDGE_THICKNESS / 2.0
		_add_collision_body(walls, Rect2(edge_x - EDGE_THICKNESS / 2.0, 0, EDGE_THICKNESS, segment_height))
		_add_collision_body(walls, Rect2(edge_x - EDGE_THICKNESS / 2.0, SCREEN_SIZE.y - segment_height, EDGE_THICKNESS, segment_height))


func _is_open(direction: Vector2i) -> bool:
	return bool(_open_exits.get(direction, false))
