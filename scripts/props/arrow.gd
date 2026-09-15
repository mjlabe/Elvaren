class_name Arrow
extends Area2D

@export var speed: float = 180.0
@export var lifetime: float = 1.0
@export var damage: int = 1

var _direction: Vector2 = Vector2.RIGHT
var _timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += _direction * speed * delta
	_timer += delta
	if _timer >= lifetime:
		queue_free()


func setup(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage, global_position, 80.0)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("switch"):
		if area.has_method("trigger"):
			area.call("trigger")
		queue_free()
