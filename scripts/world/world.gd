class_name World
extends Node2D

@export var player_scene: PackedScene
@export var area_scene: PackedScene
@export var start_area: Vector2i = Vector2i(3, 6)

const MAP_GRID_SIZE: Vector2i = Vector2i(8, 8)
const AREA_WIDTH: float = 384.0
const AREA_HEIGHT: float = 288.0
const WORLD_SEED: int = 81473
const TRANSITION_COOLDOWN: float = 0.15
const MIN_ENEMY_OBSTACLE_DISTANCE_SQUARED: float = 28.0 * 28.0
const MIN_ENEMY_SEPARATION_SQUARED: float = 32.0 * 32.0
const DUNGEON_AREA: Vector2i = Vector2i(4, 5)
const DUNGEON_SCENE: String = "res://scenes/props/dungeon_entrance.tscn"
const ENEMY_SCENES: Dictionary = {
	"slime": "res://scenes/enemies/slime.tscn",
	"bat": "res://scenes/enemies/bat.tscn",
	"snake": "res://scenes/enemies/snake.tscn",
	"skeleton": "res://scenes/enemies/skeleton.tscn",
	"sand_worm": "res://scenes/enemies/sand_worm.tscn"
}

var _map: Dictionary = {}
var _player: Player = null
var _current_area: WorldArea = null
var _transitioning: bool = false


func _ready() -> void:
	HUD.visible = true
	var is_new_game := PlayerData.current_scene.is_empty()
	_build_world_map()
	PlayerData.current_scene = scene_file_path
	_player = player_scene.instantiate() as Player
	if _player == null:
		push_error("World: failed to instantiate player")
		return
	add_child(_player)
	var area := start_area if is_new_game else PlayerData.world_area
	if not _map.has(area):
		area = start_area
	_load_area(area, Vector2i.ZERO)


func _build_world_map() -> void:
	_map.clear()
	for y in range(MAP_GRID_SIZE.y):
		for x in range(MAP_GRID_SIZE.x):
			var coords := Vector2i(x, y)
			_map[coords] = _generate_area_data(coords)


func _generate_area_data(coords: Vector2i) -> Dictionary:
	var biome := _get_biome(coords)
	var palette := _get_biome_palette(biome)
	var random := RandomNumberGenerator.new()
	random.seed = WORLD_SEED + coords.x * 73856093 + coords.y * 19349663
	var waters := _generate_waters(biome, coords)
	var obstacles := _generate_obstacles(biome, waters, random)
	var data := {
		"name": _get_area_name(biome, coords),
		"biome": biome,
		"base_color": palette["base"],
		"path_color": palette["path"],
		"paths": [Rect2(0, 128, 384, 32), Rect2(176, 0, 32, 288)],
		"waters": waters,
		"obstacles": obstacles,
		"enemies": _generate_enemy_spawns(biome, waters, obstacles, random)
	}
	if coords == DUNGEON_AREA:
		data["name"] = "Thornveil Gate"
		data["dungeon"] = DUNGEON_SCENE
		data["dungeon_position"] = Vector2(288, 144)
	return data


func _get_biome(coords: Vector2i) -> String:
	if coords == DUNGEON_AREA:
		return "forest"
	if coords.y == 0:
		return "snow" if coords.x <= 4 else "highland"
	if coords.x <= 1 and coords.y >= 2:
		return "desert"
	if coords.x >= 6 and coords.y <= 4:
		return "coast"
	if coords.y >= 5 and coords.x >= 2 and coords.x <= 5:
		return "meadow"
	if coords.x >= 2 and coords.x <= 5 and coords.y >= 2 and coords.y <= 4:
		return "forest"
	return "swamp"


func _get_biome_palette(biome: String) -> Dictionary:
	match biome:
		"forest": return {"base": Color("397a3f"), "path": Color("ad9560")}
		"desert": return {"base": Color("b79552"), "path": Color("d4bd78")}
		"coast": return {"base": Color("548f4a"), "path": Color("c4aa68")}
		"swamp": return {"base": Color("476d3e"), "path": Color("9f8957")}
		"snow": return {"base": Color("b8ced0"), "path": Color("d7d2b2")}
		"highland": return {"base": Color("6f745f"), "path": Color("b3a174")}
		_: return {"base": Color("559849"), "path": Color("c9ad68")}


func _get_area_name(biome: String, coords: Vector2i) -> String:
	var region_name := "Hearthlands"
	match biome:
		"forest": region_name = "Thornveil"
		"desert": region_name = "Sunglass Dunes"
		"coast": region_name = "Aqualis Reach"
		"swamp": region_name = "Mirefen"
		"snow": region_name = "Frostcrown"
		"highland": region_name = "Cinder Peaks"
	return "%s  %d-%d" % [region_name, coords.x + 1, coords.y + 1]


func _generate_waters(biome: String, coords: Vector2i) -> Array[Rect2]:
	var waters: Array[Rect2] = []
	if biome == "coast":
		var water_on_right := coords.x == MAP_GRID_SIZE.x - 1
		var water_x := 224.0 if water_on_right else 16.0
		waters.append(Rect2(water_x, 16, 144, 104))
		waters.append(Rect2(water_x, 168, 144, 104))
	elif biome == "swamp":
		waters.append(Rect2(32, 32, 96, 72))
		waters.append(Rect2(256, 184, 96, 72))
	return waters


func _generate_obstacles(biome: String, waters: Array[Rect2], random: RandomNumberGenerator) -> Array[Dictionary]:
	var obstacles: Array[Dictionary] = []
	var count := 34 if biome == "forest" else 24
	if biome == "meadow":
		count = 20
	elif biome == "desert" or biome == "coast":
		count = 18
	for index in range(count):
		var position_value := _random_clear_position(waters, random, true)
		var obstacle_type := "tree"
		match biome:
			"desert": obstacle_type = "cactus" if index % 3 != 0 else "rock"
			"snow": obstacle_type = "pine" if index % 4 != 0 else "rock"
			"highland": obstacle_type = "rock" if index % 3 != 0 else "pine"
			"swamp": obstacle_type = "shrub" if index % 2 == 0 else "dead_tree"
			"coast": obstacle_type = "rock" if index % 2 == 0 else "shrub"
			"meadow": obstacle_type = "flower" if index % 4 == 0 else "tree"
		obstacles.append({"type": obstacle_type, "position": position_value})
	return obstacles


func _generate_enemy_spawns(biome: String, waters: Array[Rect2], obstacles: Array[Dictionary], random: RandomNumberGenerator) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	var pool := _get_enemy_pool(biome)
	var count := 5 if biome == "forest" or biome == "swamp" else 3
	var pool_offset := random.randi_range(0, pool.size() - 1)
	for index in range(count):
		var enemy_type := pool[(pool_offset + index) % pool.size()]
		spawns.append({
			"scene": ENEMY_SCENES[enemy_type],
			"position": _random_enemy_position(waters, obstacles, spawns, random)
		})
	return spawns


func _random_enemy_position(waters: Array[Rect2], obstacles: Array[Dictionary], existing_spawns: Array[Dictionary], random: RandomNumberGenerator) -> Vector2:
	for attempt in range(64):
		var position_value := _random_clear_position(waters, random, false)
		var blocked := false
		for obstacle in obstacles:
			if str(obstacle.get("type", "")) == "flower":
				continue
			var obstacle_position: Vector2 = obstacle.get("position", Vector2.ZERO)
			if position_value.distance_squared_to(obstacle_position) < MIN_ENEMY_OBSTACLE_DISTANCE_SQUARED:
				blocked = true
				break
		if blocked:
			continue
		for spawn in existing_spawns:
			var spawn_position: Vector2 = spawn.get("position", Vector2.ZERO)
			if position_value.distance_squared_to(spawn_position) < MIN_ENEMY_SEPARATION_SQUARED:
				blocked = true
				break
		if not blocked:
			return position_value
	return Vector2(AREA_WIDTH / 2.0, AREA_HEIGHT / 2.0)


func _get_enemy_pool(biome: String) -> Array[String]:
	match biome:
		"forest": return ["slime", "snake", "skeleton", "bat"]
		"desert": return ["sand_worm", "snake", "skeleton"]
		"coast": return ["slime", "bat", "skeleton"]
		"swamp": return ["slime", "snake", "bat", "skeleton"]
		"snow": return ["skeleton", "bat", "slime"]
		"highland": return ["skeleton", "bat", "snake"]
		_: return ["slime", "bat", "snake"]


func _random_clear_position(waters: Array[Rect2], random: RandomNumberGenerator, avoid_paths: bool) -> Vector2:
	for attempt in range(32):
		var position_value := Vector2(random.randi_range(2, 21) * 16 + 8, random.randi_range(2, 15) * 16 + 8)
		if avoid_paths and (absf(position_value.x - AREA_WIDTH / 2.0) < 48.0 or absf(position_value.y - AREA_HEIGHT / 2.0) < 48.0):
			continue
		var in_water := false
		for water in waters:
			if water.grow(16.0).has_point(position_value):
				in_water = true
				break
		if not in_water:
			return position_value
	return Vector2(128, 128)


func _load_area(coords: Vector2i, from_direction: Vector2i) -> void:
	if not _map.has(coords):
		_transitioning = false
		return
	var previous_position := _player.global_position
	if _current_area != null:
		_current_area.queue_free()
	_current_area = area_scene.instantiate() as WorldArea
	if _current_area == null:
		push_error("World: failed to instantiate area")
		_transitioning = false
		return
	var area_data: Dictionary = _map[coords]
	_current_area.configure(coords, area_data)
	_current_area.transition_requested.connect(_on_transition)
	add_child(_current_area)
	move_child(_current_area, 0)
	_current_area.set_exit_and_wall(Vector2i.UP, _map.has(coords + Vector2i.UP))
	_current_area.set_exit_and_wall(Vector2i.DOWN, _map.has(coords + Vector2i.DOWN))
	_current_area.set_exit_and_wall(Vector2i.LEFT, _map.has(coords + Vector2i.LEFT))
	_current_area.set_exit_and_wall(Vector2i.RIGHT, _map.has(coords + Vector2i.RIGHT))
	var spawn_position: Vector2
	if from_direction == Vector2i.ZERO and PlayerData.position != Vector2.ZERO:
		spawn_position = PlayerData.position
	else:
		spawn_position = _current_area.get_spawn(from_direction)
		if from_direction.x != 0:
			spawn_position.y = clampf(previous_position.y, 40.0, AREA_HEIGHT - 40.0)
		elif from_direction.y != 0:
			spawn_position.x = clampf(previous_position.x, 40.0, AREA_WIDTH - 40.0)
	_player.global_position = spawn_position
	PlayerData.position = spawn_position
	PlayerData.world_area = coords
	GameState.set_flag("visited_%d_%d" % [coords.x, coords.y], true)
	if HUD.has_method("show_area_name"):
		HUD.show_area_name(str(area_data.get("name", "Elvaren")), coords, MAP_GRID_SIZE)
	if from_direction == Vector2i.ZERO:
		_transitioning = false
	else:
		get_tree().create_timer(TRANSITION_COOLDOWN).timeout.connect(_finish_transition)


func _finish_transition() -> void:
	_transitioning = false


func _on_transition(to_grid: Vector2i, from_direction: Vector2i) -> void:
	if _transitioning or not _map.has(to_grid):
		return
	_transitioning = true
	call_deferred("_load_area", to_grid, from_direction)
