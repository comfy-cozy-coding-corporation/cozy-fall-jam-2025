extends CharacterBody2D

const TOP_SPEED = 200
const ACCELERATION = 500
const DECELERATION = 1500
const JUMP_VELOCITY = 120
const JUMP_MAX_HOLD_TIME = 0.5
const JUMPING_GRAVITY_ACC = 100
const FALLING_GRAVITY_ACC = 500
const GLIDING_GRAVITY_ACC = 200
const GLIDING_AIR_RESISTANCE = 2.0
const GLIDING_FORWARD_ACC = 200

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
	RISE_INTO_FALLING,
	STAND_INTO_FALLING,
	FALL_INTO_GLIDING
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
	sprite.speed_scale = (speed / TOP_SPEED) * (1 - MIN_RUNNING_ANIM_SPEED) + MIN_RUNNING_ANIM_SPEED


func run_accelerate(direction, delta: float):
	sprite_face(direction)

	var delta_vel
	if sign(velocity.x) == direction:
		delta_vel = delta * direction * ACCELERATION
	else:
		delta_vel = delta * direction * DECELERATION

	if velocity.x * direction > TOP_SPEED:
		return

	velocity.x = min(TOP_SPEED, direction * (velocity.x + delta_vel)) * direction
	sprite_set_running_speed(abs(velocity.x))

func run_decelerate(delta: float):
	var delta_vel = delta * DECELERATION
	velocity.x = max(0, abs(velocity.x) - delta_vel) * sign(velocity.x)
	sprite_set_running_speed(abs(velocity.x))


var jump_window_counter: int = 0

func jump():
	change_state(State.JUMPING)
	jump_window_counter += 1
	jump_input_window.start()

	velocity.y -= JUMP_VELOCITY

	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		sprite_face(-1)
		velocity.x = -abs(velocity.x)
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		sprite_face(1)
		velocity.x = abs(velocity.x)
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
		velocity.y += JUMPING_GRAVITY_ACC * delta
	elif state == State.GLIDING:
		velocity.y += GLIDING_GRAVITY_ACC * delta
	else:
		velocity.y += FALLING_GRAVITY_ACC * delta

func apply_air_resistance(delta):
	if sign(velocity.y) <= 0:
		return
	velocity.y *= (1 - clamp(GLIDING_AIR_RESISTANCE * delta, 0, 1))


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
			State.FALLING, State.RISING: change_state(State.GLIDING)
			State.GLIDING: change_state(State.FALLING)

	if state == State.GLIDING:
		velocity.x += facing_dir * GLIDING_FORWARD_ACC * delta
		if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
			sprite_face(-1)
		elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
			sprite_face(1)

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
