class_name ClimbArea
extends Area2D

@onready var shape: CollisionShape2D = self.find_children("*", "CollisionShape2D")[0]

func snap_global(pos: Vector2) -> Vector2:
	var rect = shape.shape.get_rect()
	return Vector2(
		shape.global_position.x,
		max(pos.y, shape.global_position.y + rect.position.y)
	)
