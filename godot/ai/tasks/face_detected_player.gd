@tool
extends BTAction

func _tick(delta: float) -> Status:
	agent.turn_toward_player()
	return SUCCESS
