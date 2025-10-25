extends Node2D

func _ready() -> void:
	$trees.set_frame(randi_range(0,2))
