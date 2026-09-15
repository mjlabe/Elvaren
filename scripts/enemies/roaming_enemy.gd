class_name RoamingEnemy
extends CharacterBody2D

@export var sprite_sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(32, 32)
@export_range(1, 16, 1) var frame_columns: int = 1
@export_range(0, 16, 1) var animation_row: int = 0
@export var directional_rows: bool = false
@export_range(0, 16, 1) var row_up: int = 0
@export_range(0, 16, 1) var row_right: int = 1
@export_range(0, 16, 1) var row_down: int = 2
@export_range(0, 16, 1) var row_left: int = 3
@export var animation_fps: float = 8.0
@export var speed: float = 26.0
@export var chase_speed: float = 36.0
@export var chase_range: float = 80.0
@export var health: int = 3
@export var contact_damage: int = 1
@export var wander_time_min: float = 0.8
@export var wander_time_max: float = 2.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_dropper: HealthDropper = $HealthDropper

const MOVEMENT_COLLISION_MASK: int = (1 << 0) | (1 << 1) | (1 << 2)
const CONTACT_DISTANCE: float = 16.0
const CONTACT_COOLDOWN: float = 0.8
const HURT_DURATION: float = 0.14
const DEATH_DURATION: float = 0.12

var _target: Player = null
var _move_direction: Vector2 = Vector2.ZERO
var _facing: String = "down"
var _wander_timer: float = 0.0
var _contact_timer: float = 0.0
var _hurt_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _dying: bool = false
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_mask = MOVEMENT_COLLISION_MASK
	_random.randomize()
	animated_sprite.sprite_frames = _build_sprite_frames()
	_pick_wander_direction()
	_update_animation()


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return
	_contact_timer = maxf(_contact_timer - delta, 0.0)
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		velocity = _knockback_velocity
		move_and_slide()
		if _hurt_timer <= 0.0:
			animated_sprite.modulate = Color.WHITE
		return
	_target = _find_player()
	var distance_to_player := INF
	if _target != null:
		distance_to_player = global_position.distance_to(_target.global_position)
	if distance_to_player <= chase_range:
		_move_direction = global_position.direction_to(_target.global_position)
		velocity = _move_direction * chase_speed
	else:
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_pick_wander_direction()
		velocity = _move_direction * speed
	move_and_slide()
	_update_facing()
	_update_animation()
	if _target != null and distance_to_player <= CONTACT_DISTANCE and _contact_timer <= 0.0:
		_target.take_damage(contact_damage, global_position, 90.0)
		_contact_timer = CONTACT_COOLDOWN


func _pick_wander_direction() -> void:
	_wander_timer = _random.randf_range(wander_time_min, wander_time_max)
	if _random.randf() < 0.2:
		_move_direction = Vector2.ZERO
		return
	_move_direction = Vector2.from_angle(_random.randf_range(0.0, TAU))


func _update_facing() -> void:
	if _move_direction == Vector2.ZERO:
		return
	if absf(_move_direction.x) > absf(_move_direction.y):
		_facing = "right" if _move_direction.x > 0.0 else "left"
	else:
		_facing = "down" if _move_direction.y > 0.0 else "up"
	if not directional_rows:
		animated_sprite.flip_h = _move_direction.x < 0.0


func _update_animation() -> void:
	var animation_name := "move_" + _facing if directional_rows else "move"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0] as Player


func take_damage(amount: int, source: Vector2, knockback: float) -> void:
	if _dying or _hurt_timer > 0.0:
		return
	health -= amount
	if health <= 0:
		_die()
		return
	var direction := source.direction_to(global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_knockback_velocity = direction * knockback
	_hurt_timer = HURT_DURATION
	animated_sprite.modulate = Color("ff8888")


func _die() -> void:
	_dying = true
	health_dropper.try_drop(global_position, get_parent())
	collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, DEATH_DURATION)
	tween.finished.connect(queue_free)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if sprite_sheet == null:
		return frames
	if directional_rows:
		_add_animation(frames, "move_up", row_up)
		_add_animation(frames, "move_right", row_right)
		_add_animation(frames, "move_down", row_down)
		_add_animation(frames, "move_left", row_left)
	else:
		_add_animation(frames, "move", animation_row)
	return frames


func _add_animation(frames: SpriteFrames, animation_name: String, row: int) -> void:
	frames.add_animation(animation_name)
	var available_columns := int(sprite_sheet.get_width()) / frame_size.x
	var columns := mini(frame_columns, available_columns)
	for column in range(columns):
		var atlas := AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(column * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
		frames.add_frame(animation_name, atlas)
	frames.set_animation_speed(animation_name, animation_fps)
	frames.set_animation_loop(animation_name, true)
