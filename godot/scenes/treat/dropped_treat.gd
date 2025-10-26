class_name DroppedTreat
extends RigidBody2D

const _scene = preload("res://scenes/treat/dropped_treat.tscn")


@export var _type: Treat.Type = Treat.Type.MYSTERY_BALL


@onready var _treat: Treat = $Treat

static func create(type: Treat.Type) -> DroppedTreat:
	var dropped_treat: DroppedTreat = _scene.instantiate()
	dropped_treat._type = type
	return dropped_treat

func start_pickup_cooldown():
	_treat.start_pickup_cooldown()

func _process(_delta: float) -> void:
	if _treat.get_type() != _type:
		_treat.set_type(_type)

func _on_treat_tree_exiting():
	queue_free()
