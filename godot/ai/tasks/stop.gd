@tool
extends BTAction

func _tick(delta: float) -> Status:
	agent.stop_moving()
	return SUCCESS
