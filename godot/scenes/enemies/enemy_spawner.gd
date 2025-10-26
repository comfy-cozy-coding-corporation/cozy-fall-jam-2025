extends Node2D

@export var number_of_enemies: int = 8
@export var enemy_max_distance: float = 750
@export var position_variation: float = 50

func _ready() -> void:
	for child in get_children():
		child.queue_free()

	var positions: Array[float]
	var start = -enemy_max_distance
	var range_width = 2 * enemy_max_distance

	for i in range(number_of_enemies):
		positions.push_back(start + (i as float) / (number_of_enemies - 1) * range_width)

	for i in range(positions.size()):
		positions[i] = positions[i] + randf_range(-position_variation, position_variation)

	for pos in positions:
		var enemy = Enemy.create()
		enemy.position.x = pos
		self.add_child(enemy)
