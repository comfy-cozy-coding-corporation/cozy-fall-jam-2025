class_name Treat
extends Area2D

const _scene = preload("res://scenes/treat/treat.tscn")

enum Type {
	MYSTERY_BALL,
	CROISSANT,
	LOLLYPOP,
	CHOCOLATE,
}

@export var _type: Type = Type.MYSTERY_BALL

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _cooldown_timer: Timer = $PickupCooldown

var _displayed_type = null
var _on_cooldown = false

static func create(type: Type) -> Treat:
	var treat: Treat = _scene.instantiate()
	treat.set_type(type)
	return treat

static func points_for_type(type: Type) -> int:
	match type:
		Type.MYSTERY_BALL: return 10000
		Type.CROISSANT: return 1000
		Type.LOLLYPOP: return 2000
		Type.CHOCOLATE: return 3000
	return 0

func get_type() -> Type:
	return _type

func set_type(type: Type):
	_type = type

func get_points() -> int:
	return points_for_type(get_type())

func start_pickup_cooldown():
	_cooldown_timer.stop()
	_cooldown_timer.start()
	_on_cooldown = true

func is_on_cooldown() -> bool:
	return _on_cooldown


func _process(_delta) -> void:
	if _displayed_type == _type:
		return
	match self._type:
		Type.MYSTERY_BALL:
			self._sprite.play("mystery-ball")
			self.rotation = randf_range(0, TAU)
		Type.CHOCOLATE:
			self._sprite.play("chocolate")
		Type.LOLLYPOP:
			self._sprite.play("lollypop")
		Type.CROISSANT:
			self._sprite.play("croissant")
	_displayed_type = _type


func _on_pickup_cooldown_timeout() -> void:
	_on_cooldown = false
