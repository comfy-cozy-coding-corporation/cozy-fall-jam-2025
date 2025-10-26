extends BTCondition


# Called when the node enters the scene tree for the first time.
func _tick(delta: float) -> Status:
	if agent.has_treat:
		return SUCCESS
	else:
		return FAILURE
