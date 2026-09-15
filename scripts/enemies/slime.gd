class_name SlimeEnemy
extends CharacterBody2D

@export var speed: float = 26.0
@export var chase_speed: float = 34.0
@export var chase_range: float = 80.0
@export var health: int = 3
@export var contact_damage: int = 1
@export var wander_time_min: float = 0.8
@export var wander_time_max: float = 2.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const FRAME_SIZE: Vector2i = Vector2i(64, 64)
const IDLE_SHEET: String = "res://assets/art/enemies/slime1/Idle/Slime1_Idle_full.png"
const WALK_SHEET: String = "res://assets/art/enemies/slime1/Walk/Slime1_Walk_full.png"
const DEATH_SHEET: String = "res://assets/art/enemies/slime1/Death/Slime1_Death_full.png"
const DIRECTIONS: Array[String] = ["down", "up", "right", "left"]
const CONTACT_DISTANCE: float = 16.0
const CONTACT_COOLDOWN: float = 0.8
const HURT_DURATION: float = 0.14

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
	_random.randomize()
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_pick_wander_direction()
	animated_sprite.play("idle_down")


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
	var angle := _random.randf_range(0.0, TAU)
	_move_direction = Vector2.from_angle(angle)


func _update_facing() -> void:
	if _move_direction == Vector2.ZERO:
		return
	if absf(_move_direction.x) > absf(_move_direction.y):
		_facing = "right" if _move_direction.x > 0.0 else "left"
	else:
		_facing = "down" if _move_direction.y > 0.0 else "up"


func _update_animation() -> void:
	var prefix := "idle" if velocity.length_squared() < 1.0 else "walk"
	var animation_name := prefix + "_" + _facing
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
		_dying = true
		collision_shape.set_deferred("disabled", true)
		animated_sprite.play("death_" + _facing)
		return
	var direction := source.direction_to(global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_knockback_velocity = direction * knockback
	_hurt_timer = HURT_DURATION
	animated_sprite.modulate = Color("ff8888")


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var idle_texture := load(IDLE_SHEET) as Texture2D
	var walk_texture := load(WALK_SHEET) as Texture2D
	var death_texture := load(DEATH_SHEET) as Texture2D
	for row in range(DIRECTIONS.size()):
		_add_sheet_animation(frames, "idle_" + DIRECTIONS[row], idle_texture, row, 6, 6.0, true)
		_add_sheet_animation(frames, "walk_" + DIRECTIONS[row], walk_texture, row, 8, 10.0, true)
		_add_sheet_animation(frames, "death_" + DIRECTIONS[row], death_texture, row, 10, 12.0, false)
	return frames


func _add_sheet_animation(frames: SpriteFrames, animation_name: String, texture: Texture2D, row: int, columns: int, fps: float, loop: bool) -> void:
	frames.add_animation(animation_name)
	for column in range(columns):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(column * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, atlas)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, loop)


func _on_animation_finished() -> void:
	if _dying and animated_sprite.animation.begins_with("death_"):
		queue_free()
