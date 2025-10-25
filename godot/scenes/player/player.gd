class_name Player
extends CharacterBody2D

@export_group("Movement")

@export_subgroup("Running")
@export var max_running_speed: float = 200
@export var running_acceleration: float = 500
@export var running_turnaround_acceleration: float = 10000
@export var running_deceleration: float = 1500

@export_subgroup("Jumping")
@export var jump_velocity: float = 120
@export var jumping_gravity: float = 100
@export var jump_max_hold_time: float = 0.5

@export_subgroup("Falling")
@export var falling_gravity: float = 500
@export var max_air_control_speed: float = 100
@export var air_control_accceleration: float = 500

@export_subgroup("Gliding")
@export var glides_per_jump: int = 1
@export var max_gliding_speed: float = 300
@export var gliding_gravity: float = 200
@export var gliding_air_resistance: float = 2.0
@export var gliding_acceleration: float = 300
@export var gliding_turnaround_acceleration: float = 900

@export_subgroup("Flapping")
@export var flap_velocity: float = 280
@export var flap_forward_velocity: float = 100

@export_subgroup("Climbing")
@export var max_climbing_speed: float = 160
@export var climbing_acceleration: float = 1500
@export var climbing_turnaround_acceleration: float = 10000
@export var climbing_deceleration: float = 1500

@export_group("Visual")
@export var min_running_animation_speed: float = 0.5
@export var min_climbing_animation_speed: float = 0.5

enum State {
	STANDING,
	RUNNING,
	JUMPING,
	RISING,
	FALLING,
	GLIDING,
	CLIMBING
}

enum PlayerAnimation {
	LAND_INTO_STANDING,
	STANDING,
	RUNNING,
	JUMPING,
	FLAP,
	RISE_INTO_FALLING,
	STAND_INTO_FALLING,
	FALL_INTO_GLIDING,
	CLIMBING,
}

var state = State.STANDING

@onready var sprite: AnimatedSprite2D = $PlayerSprite
@onready var jump_input_window: Timer = $JumpInputWindow
@onready var interaction_area: Area2D = $InteractionArea

var animation_queue = []

func _play_next_animation():
	var next_anim = animation_queue.pop_front()
	if next_anim != null:
		sprite.play(next_anim)

func play(anim: PlayerAnimation):
	animation_queue.clear()
	sprite.rotation = 0
	match anim:
		PlayerAnimation.LAND_INTO_STANDING:
			sprite.play("landing")
			animation_queue.push_back("standing")
		PlayerAnimation.STANDING:
			sprite.play("standing")
		PlayerAnimation.RUNNING:
			sprite.play("running")
		PlayerAnimation.JUMPING:
			sprite.play("jumping")
		PlayerAnimation.FLAP:
			sprite.play("flap")
		PlayerAnimation.RISE_INTO_FALLING:
			sprite.play("jump_to_fall")
			animation_queue.push_back("falling")
		PlayerAnimation.STAND_INTO_FALLING:
			sprite.play("landing", -1, true)
			animation_queue.push_back("falling")
		PlayerAnimation.FALL_INTO_GLIDING:
			sprite.play("fall_to_glide")
			animation_queue.push_back("gliding")
		PlayerAnimation.CLIMBING:
			sprite.rotation = -PI / 2
			sprite.play("climbing")

func change_state(new_state: State):
	if new_state == state: return
	sprite.speed_scale = 1

	match new_state:
		State.STANDING:
			if state == State.FALLING || state == State.RISING || state == State.JUMPING || state == State.GLIDING:
				play(PlayerAnimation.LAND_INTO_STANDING)
			else:
				play(PlayerAnimation.STANDING)
		State.RUNNING:
			play(PlayerAnimation.RUNNING)
		State.JUMPING:
			if state == State.GLIDING:
				play(PlayerAnimation.FLAP)
			else:
				play(PlayerAnimation.JUMPING)
		State.FALLING:
			if state == State.JUMPING || state == State.RISING:
				play(PlayerAnimation.RISE_INTO_FALLING)
			else:
				play(PlayerAnimation.STAND_INTO_FALLING)
		State.GLIDING:
			play(PlayerAnimation.FALL_INTO_GLIDING)
		State.CLIMBING:
			play(PlayerAnimation.CLIMBING)
	state = new_state

var facing_dir = -1

func _sprite_face(direction: float):
	if direction == 0:
		return
	facing_dir = direction
	sprite.flip_h = facing_dir == 1

func _sprite_set_speed_scale(speed: float):
	sprite.speed_scale = speed

func _sprite_set_rel_speed(speed: float, max_speed: float, min_anim_speed: float):
	_sprite_set_speed_scale((abs(speed) / max_speed) * (1 - min_anim_speed) + min_anim_speed)

func _accelerate(
	delta: float,
	current_velocity: float,
	direction: float,
	max_speed: float,
	acceleration: float,
	turnaround_acceleration: float
) -> float :
	if direction == 0:
		return current_velocity

	var delta_vel
	if sign(current_velocity) == direction:
		delta_vel = delta * direction * acceleration
	else:
		delta_vel = delta * direction * turnaround_acceleration

	if current_velocity * direction > max_speed:
		return current_velocity

	return min(max_speed, direction * (current_velocity + delta_vel)) * direction

func _decelerate(delta: float, current_velocity: float, deceleration: float) -> float:
	return _accelerate(delta, current_velocity, -sign(current_velocity), 0, deceleration, deceleration)

func _input_direction_h():
	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		return -1
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		return 1
	else:
		return 0

func _input_direction_v() -> float:
	if Input.is_action_pressed("move_up") && !Input.is_action_pressed("move_down"):
		return -1
	elif Input.is_action_pressed("move_down") && !Input.is_action_pressed("move_up"):
		return 1
	else:
		return 0

func _instant_turnaround(max_speed: float):
	var dir = _input_direction_h()
	_sprite_face(dir)
	velocity.x = dir * max(dir * velocity.x, max_speed)

	
func _jump(vel: float, turnaround_speed: float):
	if velocity.y < vel:
		velocity.y = max(velocity.y, 0) - vel
	_instant_turnaround(turnaround_speed)

func _start_ground_jump_input_window():
	jump_window_counter += 1
	jump_input_window.start(jump_max_hold_time)

var jump_window_counter: int = 0
var glides_available = 0

func _process_on_ground(delta: float):
	glides_available = glides_per_jump

	if !is_on_floor():
		change_state(State.FALLING)
		return
	
	if Input.is_action_pressed("jump"):
		change_state(State.JUMPING)
		_jump(jump_velocity, max_running_speed)
		_start_ground_jump_input_window()
		return

	var dir = _input_direction_h()
	if dir != 0:
		change_state(State.RUNNING)
		_sprite_face(dir)
		velocity.x = _accelerate(delta, velocity.x, facing_dir, max_running_speed, running_acceleration, running_turnaround_acceleration)
	else:
		velocity.x = _decelerate(delta, velocity.x, running_deceleration)

	match state:
		State.RUNNING:
			if velocity.x == 0:
				change_state(State.STANDING)
			else:
				_sprite_set_rel_speed(velocity.x, max_running_speed, min_running_animation_speed)
		State.STANDING:
			velocity.x = _decelerate(delta, velocity.x, running_deceleration)


func _apply_gravity(delta: float):
	if state == State.JUMPING:
		velocity.y += jumping_gravity * delta
	elif state == State.GLIDING:
		velocity.y += gliding_gravity * delta
	else:
		velocity.y += falling_gravity * delta

func _apply_air_resistance(delta: float):
	if sign(velocity.y) <= 0:
		return
	velocity.y *= (1 - clamp(gliding_air_resistance * delta, 0, 1))


func _process_in_air(delta: float):
	if state == State.JUMPING && (jump_window_counter == 0 || !Input.is_action_pressed("jump")):
		change_state(State.RISING)

	if state == State.RISING && sign(velocity.y) != -1:
		change_state(State.FALLING)

	if state != State.JUMPING && is_on_floor():
		change_state(State.STANDING)
		return
	
	if Input.is_action_just_pressed("jump"):
		match state:
			State.FALLING, State.RISING:
				if glides_available > 0:
					change_state(State.GLIDING)
					glides_available -= 1
			State.GLIDING:
				_jump(flap_velocity, flap_forward_velocity)
				play(PlayerAnimation.FLAP)
				change_state(State.RISING)

	var dir = _input_direction_h()

	_apply_gravity(delta)

	match state:
		State.GLIDING:
			_sprite_face(dir)
			velocity.x = _accelerate(delta, velocity.x, facing_dir, max_gliding_speed, gliding_acceleration, gliding_turnaround_acceleration)
			_apply_air_resistance(delta)
		State.RISING, State.FALLING:
			velocity.x = _accelerate(delta, velocity.x, dir, max_air_control_speed, air_control_accceleration, air_control_accceleration)
			_sprite_face(sign(velocity.x))

func _get_climb_area() -> ClimbArea:
	var climbing_area: ClimbArea = null
	var closest_distance = INF
	var areas: Array[Area2D] = interaction_area.get_overlapping_areas()
	for area in areas:
		if !(area is ClimbArea):
			continue

		var dist = area.position.distance_squared_to(self.position)
		if dist < closest_distance:
			closest_distance = dist
			climbing_area = area
	
	return climbing_area

var climbing_on: ClimbArea = null

func _check_climbing():
	climbing_on = _get_climb_area()
	if climbing_on == null: return

	if Input.is_action_pressed("move_up") || Input.is_action_pressed("move_down"):
		change_state(State.CLIMBING)

func _process_climbing(delta):
	if climbing_on == null:
		change_state(State.FALLING)
		return

	velocity.x = 0
	if velocity.y == 0:
		_sprite_set_speed_scale(0)
	else:
		_sprite_set_rel_speed(abs(velocity.y), max_climbing_speed, min_climbing_animation_speed)

	var dir = _input_direction_v()
	if dir != 0:
		_sprite_face(dir)
		velocity.y = _accelerate(delta, velocity.y, dir, max_climbing_speed, climbing_acceleration, climbing_turnaround_acceleration)
	else:
		velocity.y = _decelerate(delta, velocity.y, climbing_deceleration)

func _adjust_position():
	if climbing_on != null:
		global_position = climbing_on.snap_global(global_position)

func _physics_process(delta: float) -> void:
	_check_climbing()
	match state:
		State.CLIMBING:
			_process_climbing(delta)
		State.STANDING, State.RUNNING:
			_process_on_ground(delta)
		State.JUMPING, State.RISING, State.FALLING, State.GLIDING:
			_process_in_air(delta)
	move_and_slide()
	_adjust_position()


func _ready() -> void:
	sprite.animation_finished.connect(_play_next_animation)
	jump_input_window.wait_time = jump_max_hold_time
	jump_input_window.one_shot = true
	jump_input_window.timeout.connect(func(): jump_window_counter -= 1)
