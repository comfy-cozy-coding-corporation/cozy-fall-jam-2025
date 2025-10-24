extends Node2D


@export var bush_scene: PackedScene

@export var min_bushes: int = 3
@export var max_bushes: int = 5

# Defines the valid positions for a bush to spawn
# bush_pos_area[0] represents the min. x & y coordinates
# bush_pos_area[1] represents the max. x & y coordinates
@export var bush_pos_area: PackedVector2Array = [Vector2(-450, -32), Vector2(450, 10)]

func _ready() -> void:
	var amount_bushes = randi_range(min_bushes, max_bushes)
	
	for i in range(amount_bushes):
		var new_bush_pos = Vector2(
			randi_range(bush_pos_area[0].x, bush_pos_area[1].x), 
			randi_range(bush_pos_area[0].y, bush_pos_area[1].y)
		)
		var bush_instance: Node2D = bush_scene.instantiate()
		self.add_child(bush_instance)
		bush_instance.position = new_bush_pos
	
