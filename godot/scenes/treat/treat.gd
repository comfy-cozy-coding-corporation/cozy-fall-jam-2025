class_name Treat
extends Area2D

const _scene = preload("res://scenes/treat/treat.tscn")

enum Type {
	MYSTERY_BALL
}

@export var _type: Type = Type.MYSTERY_BALL

@onready var _sprite: AnimatedSprite2D = $Sprite

var _displayed_type = null

static func create(type: Type) -> Treat:
	var treat: Treat = _scene.instantiate()
	treat.set_type(type)
	return treat

func get_type() -> Type:
	return _type

func set_type(type: Type):
	_type = type


func _process(_delta) -> void:
	if _displayed_type == _type:
		return
	match self._type:
		Type.MYSTERY_BALL:
			self._sprite.play("mystery-ball")
			self.rotation = randf_range(0, TAU)
	_displayed_type = _type
