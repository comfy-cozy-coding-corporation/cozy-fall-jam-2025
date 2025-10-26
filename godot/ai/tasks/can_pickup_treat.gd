@tool
extends BTCondition


func _tick(delta: float) -> Status:
	if agent.can_pickup_treat():
		return SUCCESS
	else:
		return FAILURE
