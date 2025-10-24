extends CharacterBody2D

const GLIDES_PER_JUMP = 1
const MAX_RUNNING_SPEED = 200
const MAX_FALL_CONTROL_SPEED = 100
const MAX_GLIDING_SPEED = 300
const RUNNING_FORWARD_ACCELERATION = 500
const RUNNING_BACKWARD_ACCELERATION = 1800
const RUNNING_DECELERATION = 1500
const FALLING_ACCELERATION = 500
const GLIDING_FORWARD_ACCELERATION = 300
const GLIDING_BACKWARD_ACCELERATION = 900
const JUMP_VELOCITY = 120
const JUMP_MAX_HOLD_TIME = 0.5
const FLAP_VELOCITY = 280
const FLAP_FORWARD_VELOCITY = 100
const JUMPING_GRAVITY = 100
const FALLING_GRAVITY = 500
const GLIDING_GRAVITY = 200
const GLIDING_AIR_RESISTANCE = 2.0

const MIN_RUNNING_ANIM_SPEED = 0.5

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

func sprite_face(direction):
	facing_dir = direction
	sprite.flip_h = facing_dir == 1

func sprite_set_running_speed(speed):
	if state != State.RUNNING: return
	sprite.speed_scale = (speed / MAX_RUNNING_SPEED) * (1 - MIN_RUNNING_ANIM_SPEED) + MIN_RUNNING_ANIM_SPEED


func run_accelerate(direction, delta: float):
	sprite_face(direction)

	var delta_vel
	if sign(velocity.x) == direction:
		delta_vel = delta * direction * RUNNING_FORWARD_ACCELERATION
	else:
		delta_vel = delta * direction * RUNNING_BACKWARD_ACCELERATION

	if velocity.x * direction > MAX_RUNNING_SPEED:
		return

	velocity.x = min(MAX_RUNNING_SPEED, direction * (velocity.x + delta_vel)) * direction
	sprite_set_running_speed(abs(velocity.x))

func run_decelerate(delta: float):
	var delta_vel = delta * RUNNING_DECELERATION
	velocity.x = max(0, abs(velocity.x) - delta_vel) * sign(velocity.x)
	sprite_set_running_speed(abs(velocity.x))


var jump_window_counter: int = 0
var glides_available = 0


func jump():
	change_state(State.JUMPING)
	jump_window_counter += 1
	jump_input_window.start()

	glides_available = GLIDES_PER_JUMP

	velocity.y -= JUMP_VELOCITY

	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
		velocity.x = -max(abs(velocity.x), MAX_RUNNING_SPEED)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)
		velocity.x = max(abs(velocity.x), MAX_RUNNING_SPEED)
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
		velocity.y += JUMPING_GRAVITY * delta
	elif state == State.GLIDING:
		velocity.y += GLIDING_GRAVITY * delta
	else:
		velocity.y += FALLING_GRAVITY * delta

func apply_air_resistance(delta):
	if sign(velocity.y) <= 0:
		return
	velocity.y *= (1 - clamp(GLIDING_AIR_RESISTANCE * delta, 0, 1))



func flap():
	if velocity.y > -FLAP_VELOCITY:
		velocity.y = max(velocity.y, 0) - FLAP_VELOCITY

	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
		velocity.x = -max(-velocity.x, FLAP_FORWARD_VELOCITY)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)
		velocity.x = max(velocity.x, FLAP_FORWARD_VELOCITY)
	else:
		velocity.x = 0

	play(PlayerAnimation.FLAP)
	change_state(State.RISING)

func glide_accelerate(delta: float):
	var delta_vel
	if sign(velocity.x) == facing_dir:
		delta_vel = GLIDING_FORWARD_ACCELERATION * delta * facing_dir
	else:
		delta_vel = GLIDING_BACKWARD_ACCELERATION * delta * facing_dir

	velocity.x = min(MAX_GLIDING_SPEED, facing_dir * (velocity.x + delta_vel)) * facing_dir
	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)

func fall_accelerate(direction: float, delta: float):
	var delta_vel = delta * direction * FALLING_ACCELERATION
	velocity.x = min(MAX_RUNNING_SPEED, direction * (velocity.x + delta_vel)) * direction


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
	jump_input_window.wait_time = JUMP_MAX_HOLD_TIME
	jump_input_window.one_shot = true
	jump_input_window.timeout.connect(func(): jump_window_counter -= 1)
