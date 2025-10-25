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

@export_group("Visual")
@export var min_running_animation_speed: float = 0.5


enum State {
	STANDING,
	RUNNING,
	JUMPING,
	RISING,
	FALLING,
	GLIDING
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
}

var state = State.STANDING

@onready var sprite: AnimatedSprite2D = self.find_child("PlayerSprite")
@onready var jump_input_window: Timer = self.find_child("JumpInputWindow")

var animation_queue = []

func play_next_animation():
	var next_anim = animation_queue.pop_front()
	if next_anim != null:
		sprite.play(next_anim)

func play(anim: PlayerAnimation):
	animation_queue.clear()
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

func change_state(new_state):
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
	state = new_state

var facing_dir = -1

func sprite_face(direction: float):
	facing_dir = direction
	sprite.flip_h = facing_dir == 1

func sprite_set_running_speed(speed: float):
	if state != State.RUNNING: return
	sprite.speed_scale = (speed / max_running_speed) * (1 - min_running_animation_speed) + min_running_animation_speed


func run_accelerate(direction: float, delta: float):
	sprite_face(direction)

	var delta_vel
	if sign(velocity.x) == direction:
		delta_vel = delta * direction * running_acceleration
	else:
		delta_vel = delta * direction * running_turnaround_acceleration

	if velocity.x * direction > max_running_speed:
		return

	velocity.x = min(max_running_speed, direction * (velocity.x + delta_vel)) * direction
	sprite_set_running_speed(abs(velocity.x))

func run_decelerate(delta: float):
	var delta_vel = delta * running_deceleration
	velocity.x = max(0, abs(velocity.x) - delta_vel) * sign(velocity.x)
	sprite_set_running_speed(abs(velocity.x))


var jump_window_counter: int = 0
var glides_available = 0


func jump():
	change_state(State.JUMPING)
	jump_window_counter += 1
	jump_input_window.start()

	glides_available = glides_per_jump

	velocity.y -= jump_velocity

	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
		velocity.x = -max(abs(velocity.x), max_running_speed)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)
		velocity.x = max(abs(velocity.x), max_running_speed)
	else:
		velocity.x = 0

func process_on_ground(delta: float):
	if !is_on_floor():
		change_state(State.FALLING)
		return

	if Input.is_action_pressed("jump"):
		jump()
		change_state(State.JUMPING)
	elif Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		change_state(State.RUNNING)
		run_accelerate(-1, delta)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		change_state(State.RUNNING)
		run_accelerate(1, delta)
	else:
		change_state(State.STANDING)
		run_decelerate(delta)

func apply_gravity(delta):
	if state == State.JUMPING:
		velocity.y += jumping_gravity * delta
	elif state == State.GLIDING:
		velocity.y += gliding_gravity * delta
	else:
		velocity.y += falling_gravity * delta

func apply_air_resistance(delta):
	if sign(velocity.y) <= 0:
		return
	velocity.y *= (1 - clamp(gliding_air_resistance * delta, 0, 1))



func flap():
	if velocity.y > -flap_velocity:
		velocity.y = max(velocity.y, 0) - flap_velocity

	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
		velocity.x = -max(-velocity.x, flap_forward_velocity)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)
		velocity.x = max(velocity.x, flap_forward_velocity)
	else:
		velocity.x = 0

	play(PlayerAnimation.FLAP)
	change_state(State.RISING)

func glide_accelerate(delta: float):
	var delta_vel
	if sign(velocity.x) == facing_dir:
		delta_vel = gliding_acceleration * delta * facing_dir
	else:
		delta_vel = gliding_turnaround_acceleration * delta * facing_dir

	velocity.x = min(max_gliding_speed, facing_dir * (velocity.x + delta_vel)) * facing_dir
	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)

func fall_accelerate(direction: float, delta: float):
	var delta_vel = delta * direction * air_control_accceleration
	velocity.x = min(max_running_speed, direction * (velocity.x + delta_vel)) * direction


func process_in_air(delta: float):
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
			State.GLIDING: flap()

	if state == State.GLIDING:
		glide_accelerate(delta)
	elif state == State.RISING || state == State.FALLING:
		if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
			fall_accelerate(-1, delta)
		elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
			fall_accelerate(1, delta)
		sprite_face(sign(velocity.x))

	apply_gravity(delta)

	if state == State.GLIDING:
		apply_air_resistance(delta)

	

func _physics_process(delta: float) -> void:
	match state:
		State.STANDING, State.RUNNING:
			process_on_ground(delta)
		State.JUMPING, State.RISING, State.FALLING, State.GLIDING:
			process_in_air(delta)
	move_and_slide()


func _ready() -> void:
	sprite.animation_finished.connect(play_next_animation)
	jump_input_window.wait_time = jump_max_hold_time
	jump_input_window.one_shot = true
	jump_input_window.timeout.connect(func(): jump_window_counter -= 1)
