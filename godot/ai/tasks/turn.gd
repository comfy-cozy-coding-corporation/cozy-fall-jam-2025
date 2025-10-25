@tool
extends BTAction

func _tick(delta: float) -> Status:
	agent.turn_around()
	return SUCCESS
