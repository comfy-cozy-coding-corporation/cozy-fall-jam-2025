@tool
extends BTAction

@export var speed = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _tick(delta: float) -> Status:
	agent.move(speed)
	return SUCCESS
