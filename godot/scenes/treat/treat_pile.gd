class_name TreatPile
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if !(body is DroppedTreat): return

	var treat: DroppedTreat = body
	var points = treat.get_points()
	Score.add_points(points)
	$sfx_score.play()
	
	treat.queue_free()
