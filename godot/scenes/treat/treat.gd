class_name Treat
extends Area2D

const _scene = preload("res://scenes/treat/treat.tscn")

enum Type {
	MYSTERY_BALL,
	CHOCOLATE,
	LOLLYPOP,
	CROISSANT
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

func get_type() -> Type:
	return _type

func set_type(type: Type):
	_type = type

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
