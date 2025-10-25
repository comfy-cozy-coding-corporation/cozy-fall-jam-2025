class_name ClimbArea
extends Area2D

@onready var shape: CollisionShape2D = self.find_children("*", "CollisionShape2D")[0]

func snap_global(pos: Vector2) -> Vector2:
	var rect: Rect2 = shape.shape.get_rect()
	return Vector2(
		shape.global_position.x,
		shape.global_position.y + clamp(pos.y - shape.global_position.y, 0, rect.size.y)
	)
