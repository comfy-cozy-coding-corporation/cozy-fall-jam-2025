extends Node2D

func _process(delta: float) -> void:
	$BottomBench.z_index=0
	for body in $BottomArea.get_overlapping_bodies():
		if body is Player:
			$BottomBench.z_index=1
