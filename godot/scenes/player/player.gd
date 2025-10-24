extends CharacterBody2D

const TOP_SPEED = 200
const ACCELERATION = 500
const DECELERATION = 1500

const MIN_RUNNING_ANIM_SPEED = 0.5

enum State {
	IDLE,
	RUNNING
}

var state = State.IDLE

@onready var sprite: AnimatedSprite2D = self.find_child("PlayerSprite")

func change_state(new_state):
	if new_state == state: return
	sprite.speed_scale = 1
	match new_state:
		State.IDLE:
			sprite.play("idle")
		State.RUNNING:
			sprite.play("running")
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


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("move_left"):
		change_state(State.RUNNING)
		run_accelerate(-1, delta)
	elif Input.is_action_pressed("move_right"):
		change_state(State.RUNNING)
		run_accelerate(1, delta)
	else:
		change_state(State.IDLE)
		run_decelerate(delta)
	move_and_slide()

