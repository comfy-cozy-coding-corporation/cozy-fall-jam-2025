@tool
extends BTAction

enum states {
	CALM,
	SUSPICIOUS,
	ANGRY
}

@export var state = states.CALM


func _tick(delta: float) -> Status:
	match state:
		states.CALM:
			agent.set_sprite_state("default")
		states.SUSPICIOUS:
			agent.set_sprite_state("suspicious")
		states.ANGRY:
			agent.set_sprite_state("angry")
	return SUCCESS
