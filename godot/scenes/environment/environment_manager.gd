extends Node2D



@export_group("Bush Configuration")
@export var bush_scene: PackedScene
@export var min_bushes: int = 3
@export var max_bushes: int = 5
@export var bush_pos_area: CollisionShape2D
@export var bush_min_distance: int = 0
@export var bush_nodes_container: Node2D

@export_group("Tree Configuration")
@export var tree_scene: PackedScene
@export var min_trees: int = 3
@export var max_trees: int = 5
@export var tree_pos_area: CollisionShape2D
@export var tree_min_distance: int = 300
@export var tree_nodes_container: Node2D

@export_group("Bench Configuration")
@export var bench_scene: PackedScene
@export var min_benches: int = 2
@export var max_benches: int = 2
@export var bench_pos_area: CollisionShape2D
@export var bench_min_distance: int = 300
@export var bench_nodes_container: Node2D

func _ready() -> void:
	var amount_bushes = randi_range(min_bushes, max_bushes)
	generate_random_structure(bush_scene, bush_pos_area, amount_bushes, bush_min_distance, bush_nodes_container, "Bush-")
	
	var amount_trees = randi_range(min_trees, max_trees)
	generate_random_structure(tree_scene, tree_pos_area, amount_trees, tree_min_distance, tree_nodes_container, "Tree-")
	
	var amount_benches = randi_range(min_benches, max_benches)
	generate_random_structure(bench_scene, bench_pos_area, amount_benches, bench_min_distance, bench_nodes_container, "Bench-")
	
func generate_random_structure(
	scene: PackedScene,
	valid_positions: CollisionShape2D,
	amount: int,
	min_distance:int,
	parent_container: Node2D,
	node_name: String,
) -> void:
	var new_structure_positions: PackedVector2Array = [Vector2.ZERO]
	
	# Emergency exit if there's not enough space to distance out more objects just stop doing so
	var placing_iterations: int = 0
	for i in range(amount):
		if placing_iterations == 25:
			return
		var new_structure_pos = Vector2(
			randf_range(valid_positions.shape.get_rect().position.x, valid_positions.shape.get_rect().position.x + valid_positions.shape.get_rect().size.x), 
			randf_range(valid_positions.shape.get_rect().position.y, valid_positions.shape.get_rect().position.y + valid_positions.shape.get_rect().size.y)
		)
		while true:
			var position_adjusted = false
			for structure in new_structure_positions:
				if abs(new_structure_pos.x - structure.x) < min_distance:
					new_structure_pos = Vector2(
						randf_range(valid_positions.shape.get_rect().position.x, valid_positions.shape.get_rect().position.x + valid_positions.shape.get_rect().size.x), 
						randf_range(valid_positions.shape.get_rect().position.y, valid_positions.shape.get_rect().position.y + valid_positions.shape.get_rect().size.y)
					)
					position_adjusted = true
			if not position_adjusted:
				break
		placing_iterations += 1
		var structure_instance: Node2D = scene.instantiate()
		structure_instance.name = node_name + str(i)
		parent_container.add_child(structure_instance)
		structure_instance.global_position = new_structure_pos
		new_structure_positions.append(new_structure_pos)
