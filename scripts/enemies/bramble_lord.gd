class_name BrambleLord
extends CharacterBody2D

@export var speed: float = 40.0
@export var health: int = 5
@export var maiden_scene: PackedScene

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_dropper: HealthDropper = $HealthDropper

const MOVEMENT_COLLISION_MASK: int = (1 << 0) | (1 << 2)
const SHEET_PATH: String = "res://assets/art/enemies/balmer-andromalius-57x88-alpha.png"
const FRAME_SIZE: Vector2i = Vector2i(57, 88)
const GRID_COLS: int = 8
const GRID_ROWS: int = 3

var _target: Player = null
var _damage_cooldown: float = 0.0


func _ready() -> void:
	if GameState.get_flag("boss_bramble_lord_defeated"):
		if not GameState.get_flag("crystal_dunes_collected"):
			_spawn_maiden()
		queue_free()
		return
	motion_mode = MOTION_MODE_FLOATING
	collision_mask = MOVEMENT_COLLISION_MASK
	anim_sprite.sprite_frames = _build_sprite_frames()
	anim_sprite.play("idle")
	_target = _find_player()


func _physics_process(delta: float) -> void:
	if _target == null:
		_target = _find_player()
		if _target == null:
			return

	var dir := (_target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if velocity.x != 0.0:
		anim_sprite.flip_h = velocity.x < 0.0

	if global_position.distance_to(_target.global_position) < 18.0:
		_damage_cooldown -= delta
		if _damage_cooldown <= 0.0:
			_target.take_damage(1, global_position, 0.0)
			_damage_cooldown = 1.0


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


func take_damage(amount: int, _source: Vector2, _knockback: float) -> void:
	health -= amount
	if health <= 0:
		GameState.set_flag("boss_bramble_lord_defeated", true)
		health_dropper.try_drop(global_position, get_parent())
		_spawn_maiden()
		queue_free()
		return

	modulate = Color(1.0, 0.5, 0.5, 1.0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)


func _build_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var sheet := load(SHEET_PATH) as Texture2D
	if sheet == null:
		push_error("Failed to load boss sprite sheet: ", SHEET_PATH)
		return sf

	sf.add_animation("idle")
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
			sf.add_frame("idle", atlas)

	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 8.0)
	return sf


func _spawn_maiden() -> void:
	if maiden_scene == null:
		return
	var maiden := maiden_scene.instantiate() as Maiden
	if maiden == null:
		return
	maiden.crystal_id = "dunes"
	get_tree().current_scene.add_child(maiden)
	maiden.global_position = global_position + Vector2(40, 0)
