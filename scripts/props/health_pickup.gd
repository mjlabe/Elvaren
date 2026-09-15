class_name HealthPickup
extends Area2D

@export_range(1, 16, 1) var healing_amount: int = 4
@export_range(0.0, 30.0, 0.5) var lifetime: float = 10.0
@export var bob_height: float = 2.0
@export var bob_speed: float = 4.0

var _origin_y: float = 0.0
var _elapsed: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_origin_y = position.y
	body_entered.connect(_on_body_entered)
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	position.y = _origin_y + sin(_elapsed * bob_speed) * bob_height


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	PlayerData.heal(healing_amount)
	queue_free()
