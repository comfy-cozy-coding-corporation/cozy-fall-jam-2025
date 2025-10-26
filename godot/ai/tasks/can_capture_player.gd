@tool
extends BTCondition

func _tick(delta: float) -> Status:
	if agent.can_capture_player():
		return SUCCESS
	else:
		return FAILURE
		
