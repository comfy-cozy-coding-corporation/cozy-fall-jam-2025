extends Camera2D

@export var target: Player
@export var min_dist: float = 70
@export var lookahead_offset: float = 100
@export var spring_constant = 0.8
@export var velocity_compensation: float = 0.11
@export var damping_factor = 8.0

var x_velocity = 0

func _get_ideal_position() -> float:
	var direction = target.get_looking_direction()
	if direction == 0:
		return self.global_position.x
	return target.global_position.x + direction * lookahead_offset

func _spring_transform(x: float):
	return sign(x) * (pow(x + 1, 2) - 1) / 2

func _get_acceleration(ideal_pos: float):
	var pos_offset =  self.global_position.x - ideal_pos
	return -_spring_transform(spring_constant * pos_offset) - damping_factor * x_velocity

func _get_velocity_compensation() -> float:
	return velocity_compensation * target.velocity.x

func _process(delta: float) -> void:
	if target == null:
		return

	var ideal_pos = _get_ideal_position()
	var acc = _get_acceleration(ideal_pos)
	x_velocity += acc * delta + _get_velocity_compensation()
	self.global_position.x += x_velocity * delta
