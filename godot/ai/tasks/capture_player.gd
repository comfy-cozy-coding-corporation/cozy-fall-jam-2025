@tool
extends BTAction


func _tick(delta: float) -> Status:
	if agent.can_capture_player():
		agent.capture_player()
		return SUCCESS
	return FAILURE
