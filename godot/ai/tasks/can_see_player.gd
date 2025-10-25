@tool
extends BTCondition


func _tick(delta: float) -> Status:
	return SUCCESS if agent.can_see_player() else FAILURE
