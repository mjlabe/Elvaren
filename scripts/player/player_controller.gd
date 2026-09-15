class_name Player
extends CharacterBody2D

@export var speed: float = 64.0
@export var roll_speed: float = 120.0
@export var roll_duration: float = 0.25
@export var attack_cooldown: float = 0.3
@export var damage_invulnerability: float = 0.75
@export var hurt_duration: float = 0.14

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_pivot: Node2D = $SwordPivot
@onready var sword_hitbox: Area2D = $SwordPivot/SwordHitbox

const ARROW_SCENE: PackedScene = preload("res://scenes/props/arrow.tscn")
const FRAME_DIR: String = "res://assets/art/knil/fantasy_vector_character/character with sword/"

enum Facing { LEFT, RIGHT, UP, DOWN }

var _facing: Facing = Facing.DOWN
var _attacking: bool = false
var _attack_timer: float = 0.0
var _roll_timer: float = 0.0
var _rolling: bool = false
var _invulnerability_timer: float = 0.0
var _hurt_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _dying: bool = false


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	sword_pivot.visible = false
	sword_hitbox.monitoring = false
	sword_hitbox.body_entered.connect(_on_sword_hit)
	anim_sprite.sprite_frames = _build_sprite_frames()
	anim_sprite.play("idle")


func _physics_process(delta: float) -> void:
	_update_damage_timers(delta)
	if _dying:
		velocity = Vector2.ZERO
		return
	if _hurt_timer > 0.0:
		velocity = _knockback_velocity
		move_and_slide()
		PlayerData.position = global_position
		return
	if _attacking:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_end_attack()
	if _rolling:
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			_end_roll()
		_update_animation()
		move_and_slide()
		PlayerData.position = global_position
		return

	var direction := InputEvents.get_move_direction()
	_update_facing(direction)
	velocity = direction * speed
	move_and_slide()
	PlayerData.position = global_position
	_update_animation()


func _update_damage_timers(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_invulnerability_timer -= delta
		anim_sprite.visible = int(_invulnerability_timer * 20.0) % 2 == 0
		if _invulnerability_timer <= 0.0:
			anim_sprite.visible = true
	if _hurt_timer > 0.0:
		_hurt_timer -= delta


func _update_facing(direction: Vector2) -> void:
	if direction.x > 0.0:
		_facing = Facing.RIGHT
	elif direction.x < 0.0:
		_facing = Facing.LEFT
	elif direction.y > 0.0:
		_facing = Facing.DOWN
	elif direction.y < 0.0:
		_facing = Facing.UP

	match _facing:
		Facing.RIGHT:
			anim_sprite.flip_h = false
		Facing.LEFT:
			anim_sprite.flip_h = true
	sword_pivot.rotation_degrees = _get_sword_angle()


func _update_animation() -> void:
	var target := "idle"
	if _attacking:
		target = "attack"
	elif _rolling or velocity != Vector2.ZERO:
		target = "run"
	if anim_sprite.animation != target:
		anim_sprite.play(target)


func _get_sword_angle() -> float:
	match _facing:
		Facing.RIGHT: return 0.0
		Facing.LEFT: return 180.0
		Facing.DOWN: return 90.0
		Facing.UP: return -90.0
	return 0.0


func _input(event: InputEvent) -> void:
	if _rolling or _attacking or _hurt_timer > 0.0 or _dying:
		return
	if event.is_action_pressed("attack"):
		_attack()
	elif event.is_action_pressed("item"):
		_use_item()
	elif event.is_action_pressed("roll"):
		_roll()


func _attack() -> void:
	_attacking = true
	_attack_timer = attack_cooldown
	sword_pivot.visible = true
	sword_hitbox.monitoring = true
	anim_sprite.play("attack")


func _end_attack() -> void:
	_attacking = false
	sword_pivot.visible = false
	sword_hitbox.monitoring = false


func _roll() -> void:
	var direction := InputEvents.get_move_direction()
	if direction == Vector2.ZERO:
		direction = _facing_to_vector()
	_update_facing(direction)
	_rolling = true
	_roll_timer = roll_duration
	velocity = direction * roll_speed


func _end_roll() -> void:
	_rolling = false
	velocity = Vector2.ZERO


func _facing_to_vector() -> Vector2:
	match _facing:
		Facing.RIGHT: return Vector2.RIGHT
		Facing.LEFT: return Vector2.LEFT
		Facing.DOWN: return Vector2.DOWN
		Facing.UP: return Vector2.UP
	return Vector2.DOWN


func _use_item() -> void:
	if PlayerData.equipped_item == null:
		return
	if PlayerData.equipped_item.id == "bow":
		_shoot_arrow()


func _shoot_arrow() -> void:
	var direction := _facing_to_vector()
	var arrow := ARROW_SCENE.instantiate() as Arrow
	if arrow == null:
		return
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + direction * 12.0
	arrow.setup(direction)


func take_damage(amount: int, source: Vector2, knockback: float) -> void:
	if _invulnerability_timer > 0.0 or _rolling or _dying:
		return
	PlayerData.take_damage(amount)
	_invulnerability_timer = damage_invulnerability
	_hurt_timer = hurt_duration
	var direction := source.direction_to(global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_knockback_velocity = direction * knockback
	if PlayerData.health <= 0:
		_dying = true
		call_deferred("_respawn")


func _respawn() -> void:
	PlayerData.health = PlayerData.max_health
	PlayerData.health_changed.emit(PlayerData.health, PlayerData.max_health)
	PlayerData.position = Vector2.ZERO
	var scene_path := PlayerData.current_scene
	if scene_path.is_empty():
		scene_path = "res://scenes/world/world.tscn"
	SceneManager.change_scene(scene_path)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_frames(frames, "idle", ["character_idle_0", "character_idle_1", "character_idle_2", "character_idle_3"])
	_add_frames(frames, "run", ["character_run_0", "character_run_1", "character_run_2", "character_run_3"])
	_add_frames(frames, "attack", ["character_sword_Attack_0", "character_sword_Attack_1", "character_sword_Attack_2", "character_sword_Attack_3"])
	_add_frames(frames, "death", ["character_death_0", "character_death_1", "character_death_2"])
	_add_frames(frames, "jump", ["character_jump_0", "character_jump_1"])
	frames.set_animation_loop("idle", true)
	frames.set_animation_loop("run", true)
	frames.set_animation_loop("attack", false)
	frames.set_animation_loop("death", false)
	frames.set_animation_loop("jump", false)
	frames.set_animation_speed("idle", 5.0)
	frames.set_animation_speed("run", 10.0)
	frames.set_animation_speed("attack", 16.0)
	return frames


func _add_frames(frames: SpriteFrames, animation_name: String, names: Array) -> void:
	frames.add_animation(animation_name)
	for frame_name in names:
		frames.add_frame(animation_name, load(FRAME_DIR + frame_name + ".png") as Texture2D)


func _on_sword_hit(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", 1, global_position, 100.0)
