extends CharacterBody2D

const TOP_SPEED = 200
const ACCELERATION = 500
const DECELERATION = 1500
const JUMP_SPEED = 200
const FALLING_GRAVITY_ACC = 500

const MIN_RUNNING_ANIM_SPEED = 0.5

enum State {
	STANDING,
	RUNNING,
	JUMPING,
	FALLING
}

enum PlayerAnimation {
	LAND_INTO_STANDING,
	STANDING,
	RUNNING,
	JUMPING,
	JUMP_INTO_FALLING,
	STAND_INTO_FALLING,
}

var state = State.STANDING

@onready var sprite: AnimatedSprite2D = self.find_child("PlayerSprite")

var animation_queue = []

func play_next_animation():
	var next_anim = animation_queue.pop_front()
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
		PlayerAnimation.JUMP_INTO_FALLING:
			sprite.play("jump_to_fall")
			animation_queue.push_back("falling")
		PlayerAnimation.STAND_INTO_FALLING:
			sprite.play("landing", -1, true)
			animation_queue.push_back("falling")

func change_state(new_state):
	if new_state == state: return
	sprite.speed_scale = 1
	match new_state:
		State.STANDING:
			if state == State.FALLING or state == State.JUMPING:
				play(PlayerAnimation.LAND_INTO_STANDING)
			else:
				play(PlayerAnimation.STANDING)
		State.RUNNING:
			play(PlayerAnimation.RUNNING)
		State.JUMPING:
			play(PlayerAnimation.JUMPING)
		State.FALLING:
			if state == State.JUMPING:
				play(PlayerAnimation.JUMP_INTO_FALLING)
			else:
				play(PlayerAnimation.STAND_INTO_FALLING)
	state = new_state

func sprite_face(direction):
	sprite.flip_h = direction == 1

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

func jump():
	velocity.y -= JUMP_SPEED

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
	

func process_in_air(delta: float):
	if state == State.FALLING && is_on_floor():
		change_state(State.STANDING)
		return
	
	if state == State.JUMPING && sign(velocity.y) != 1:
		change_state(State.FALLING)

	velocity.y += FALLING_GRAVITY_ACC * delta

func _physics_process(delta: float) -> void:
	print(state)
	match state:
		State.STANDING, State.RUNNING:
			process_on_ground(delta)
		State.JUMPING, State.FALLING:
			process_in_air(delta)
	move_and_slide()


func _ready() -> void:
	sprite.animation_finished.connect(play_next_animation)
