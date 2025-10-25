extends Camera2D

@export var target: Node2D
@export var speed: float = 200
@export var min_dist: float = 70
@export var easing_harshness: float = 2
@export var acceleration: float = 800

var x_velocity = 0

func _process(delta: float) -> void:
	var target_x = target.global_position.x
	var dist_x = target_x - self.global_position.x 


	var ideal_velocity
	if abs(dist_x) < min_dist:
		ideal_velocity = 0
	else:
		ideal_velocity = sign(dist_x) * speed * pow(abs(dist_x), easing_harshness) / pow(abs(min_dist), easing_harshness)
	
	var velocity_diff = ideal_velocity - x_velocity
	var da = delta * sign(velocity_diff) * acceleration
	if abs(da) >= abs(velocity_diff):
		x_velocity = ideal_velocity
	else:
		x_velocity += da
	
	var dv = x_velocity * delta
	if abs(dv) >= abs(dist_x):
		self.global_position.x = target_x
		x_velocity = 0
		return
	self.global_position.x += dv
