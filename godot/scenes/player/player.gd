class_name Player
extends CharacterBody2D

@export var thrown_treats_parent: Node
@export var spawn_point: Node2D
@export var fade_animator: AnimationPlayer
@export var can_be_detected = false

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
@export var gliding_gravity: float = 175
@export var gliding_air_resistance: float = 2.0
@export var gliding_acceleration: float = 300
@export var gliding_turnaround_acceleration: float = 900

@export_subgroup("Flapping")
@export var flap_velocity: float = 300
@export var flap_forward_velocity: float = 100

@export_subgroup("Climbing")
@export var max_climbing_speed: float = 160
@export var climbing_acceleration: float = 1500
@export var climbing_turnaround_acceleration: float = 10000
@export var climbing_deceleration: float = 1500
@export var climbing_rubber_band_factor: float = 10.0
@export var climbing_rubber_band_min_speed: float = 50
@export var climbing_max_snap_distance: float = 1
@export var perch_climb_boost: float = 5

@export_subgroup("Holding")
@export var holding_gravity: float = 800
@export var max_dragging_speed: float = 70
@export var dragging_acceleration: float = 300
@export var dragging_turnaround_acceleration: float = 2000
@export var dragging_deceleration: float = 1000
@export var throwing_force: Vector2 = Vector2(8000, -2000)

@export_group("Visual")
@export var min_running_animation_speed: float = 0.5
@export var min_climbing_animation_speed: float = 0.5
@export var min_dragging_animation_speed: float = 0.0


enum State {
	STANDING,
	RUNNING,
	JUMPING,
	RISING,
	FALLING,
	GLIDING,
	CLIMBING,
	PERCHED,
	HOLDING,
	DRAGGING
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
	PERCHED,
	HOLDING,
	DRAGGING,
}

var state = State.STANDING
@export var hiding = false

@onready var sprite: AnimatedSprite2D = $PlayerSprite
@onready var jump_input_window: Timer = $JumpInputWindow
@onready var interaction_area: Area2D = $InteractionArea
@onready var paws: Node2D = $Paws
@onready var throw_origin: Node2D = $ThrowOrigin

var animation_queue = []

func respawn():
	fade_animator.play("fade")
	if state in [State.HOLDING, State.DRAGGING]:
		_throw_treat(Vector2.ZERO)
	global_position = spawn_point.global_position
	change_state(State.PERCHED)

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
		PlayerAnimation.STANDING, PlayerAnimation.PERCHED:
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
		PlayerAnimation.HOLDING:
			sprite.play("dragging_into_holding")
		PlayerAnimation.DRAGGING:
			sprite.play("dragging")

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
		State.PERCHED:
			play(PlayerAnimation.PERCHED)
		State.HOLDING:
			play(PlayerAnimation.HOLDING)
		State.DRAGGING:
			play(PlayerAnimation.DRAGGING)
	state = new_state

var facing_dir: int = -1

func get_looking_direction() -> int:
	match state:
		State.CLIMBING:
			return 0
		State.GLIDING:
			return sign(velocity.x)
	return facing_dir

func _sprite_face(direction: int):
	if direction == 0:
		return
	facing_dir = direction
	sprite.flip_h = facing_dir == 1
	paws.position.x = -direction * abs(paws.position.x)
	throw_origin.position.x = direction * abs(throw_origin.position.x)

func _sprite_set_speed_scale(speed: float):
	sprite.speed_scale = speed

func _sprite_set_rel_speed(speed: float, max_speed: float, min_anim_speed: float):
	_sprite_set_speed_scale((abs(speed) / max_speed) * (1 - min_anim_speed) + min_anim_speed)

func _accelerate(
	delta: float,
	current_velocity: float,
	direction: int,
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

func _input_direction_h() -> int:
	if Input.is_action_pressed("move_left") && !Input.is_action_pressed("move_right"):
		return -1
	elif Input.is_action_pressed("move_right") && !Input.is_action_pressed("move_left"):
		return 1
	else:
		return 0

func _input_direction_v() -> int:
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

func _ground_jump():
		change_state(State.JUMPING)
		_jump(jump_velocity, max_running_speed)
		jump_input_window.stop()
		jump_input_window.start(jump_max_hold_time)
		$sfx_jump.play()

func _touched_ground():
	glides_available = glides_per_jump

var glides_available = 0

func _process_on_ground(delta: float):
	_touched_ground()

	if !is_on_floor():
		change_state(State.FALLING)
		return
	
	if Input.is_action_pressed("jump"):
		_ground_jump()
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
			if is_zero_approx(velocity.x):
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

func _flap():
		_jump(flap_velocity, flap_forward_velocity)
		# reset speed
		velocity.x = sign(velocity.x) * min(abs(velocity.x), flap_forward_velocity)
		play(PlayerAnimation.FLAP)
		change_state(State.RISING)
		$sfx_flap.play()

func _on_jump_input_window_timeout():
	if state == State.JUMPING:
		change_state(State.RISING)

func _process_in_air(delta: float):
	if state == State.JUMPING && !Input.is_action_pressed("jump"):
		change_state(State.RISING)

	if state == State.RISING && sign(velocity.y) != -1:
		change_state(State.FALLING)

	if velocity.y <= 0 && is_on_floor():
		change_state(State.STANDING)
		return
	
	if Input.is_action_just_pressed("jump"):
		match state:
			State.FALLING, State.RISING:
				if glides_available > 0:
					change_state(State.GLIDING)
					glides_available -= 1
			State.GLIDING:
				_flap()
				return

	var dir = _input_direction_h()

	_apply_gravity(delta)

	match state:
		State.GLIDING:
			_sprite_face(dir)
			velocity.x = _accelerate(delta, velocity.x, facing_dir, max_gliding_speed, gliding_acceleration, gliding_turnaround_acceleration)
			_apply_air_resistance(delta)
		State.RISING, State.FALLING:
			velocity.x = _accelerate(delta, velocity.x, dir, max_air_control_speed, air_control_accceleration, air_control_accceleration)
			_sprite_face(round(sign(velocity.x)))

func _get_closest_interaction(cls: Variant) -> Variant:
	var interaction: Variant = null
	var closest_distance = INF
	var areas: Array[Area2D] = interaction_area.get_overlapping_areas()
	for area in areas:
		if !is_instance_of(area, cls):
			continue

		var dist = area.position.distance_squared_to(self.position)
		if dist < closest_distance:
			closest_distance = dist
			interaction = area
	
	return interaction

var _climbing_on: ClimbArea = null
var _holding_treat_type: Treat.Type = Treat.Type.MYSTERY_BALL

func _check_climbing():
	_climbing_on = _get_closest_interaction(ClimbArea)
	if _climbing_on == null: return

	if Input.is_action_pressed("move_up") || !is_on_floor() && Input.is_action_pressed("move_down"):
		change_state(State.CLIMBING)
		return

func _hold_treat(type: Treat.Type):
	_holding_treat_type = type
	var treat = Treat.create(type)
	paws.add_child(treat)

func _clear_paws():
	for child in paws.get_children():
		child.queue_free()

func _throw_treat(force: Vector2):
	if thrown_treats_parent != null:
		var dropped_treat = DroppedTreat.create(_holding_treat_type)
		thrown_treats_parent.add_child(dropped_treat)
		dropped_treat.global_position = throw_origin.global_position
		force.x *= facing_dir
		dropped_treat.start_pickup_cooldown()
		dropped_treat.apply_force(force)
	_clear_paws()

func _check_treat_pickup():
	var treat: Treat = _get_closest_interaction(Treat)
	if treat == null: return

	if !treat.is_on_cooldown() && Input.is_action_pressed("interact"):
		can_be_detected = true
		_hold_treat(treat.get_type())
		change_state(State.HOLDING)
		treat.queue_free()

func _check_throwing():
	if Input.is_action_just_pressed("interact"):
		_throw_treat(throwing_force)
		change_state(State.STANDING)

func _check_interactions():
	match state:
		State.STANDING, State.RUNNING, State.JUMPING, State.RISING, State.FALLING, State.GLIDING:
			_check_climbing()
			_check_treat_pickup()
		State.HOLDING, State.DRAGGING:
			_check_throwing()

func _climbing_rubber_band():
	if _climbing_on == null:
		return
	var ideal_global_position = _climbing_on.snap_global(global_position)
	var offs = ideal_global_position - global_position
	if offs.is_zero_approx():
		return
	velocity = offs.normalized() * max(offs.length() * climbing_rubber_band_factor, climbing_rubber_band_min_speed)

func _climbing_snap_position():
	if _climbing_on == null:
		return
	var ideal_global_position = _climbing_on.snap_global(global_position)
	if abs(global_position.x - ideal_global_position.x) < climbing_max_snap_distance:
		global_position.x = ideal_global_position.x
	if abs(global_position.y - ideal_global_position.y) < climbing_max_snap_distance:
		global_position.y = ideal_global_position.y

var facing_dir_before_climbing = null

func _reset_facing_dir_after_climbing():
	_sprite_face(facing_dir_before_climbing)
	facing_dir_before_climbing = null

func _remember_facing_dir():
	if facing_dir_before_climbing == null:
		facing_dir_before_climbing = facing_dir


func _process_climbing(delta):
	_remember_facing_dir()
	var new_climbing_on = _get_closest_interaction(ClimbArea)

	if new_climbing_on == null:
		_reset_facing_dir_after_climbing()
		if velocity.y <= 0 && Input.is_action_pressed("move_up"):
			change_state(State.PERCHED)
		else:
			change_state(State.FALLING)
		return
	else:
		_climbing_on = new_climbing_on

	_touched_ground()
	velocity.x = 0

	if Input.is_action_just_pressed("jump"):
		_ground_jump()
		return


	_climbing_rubber_band()

	if velocity.is_zero_approx():
		_sprite_set_speed_scale(0)
	else:
		_sprite_set_rel_speed(velocity.length(), max_climbing_speed, min_climbing_animation_speed)


	var dir = _input_direction_v()

	if dir == 1 && is_on_floor():
		_reset_facing_dir_after_climbing()
		change_state(State.STANDING)
		return

	if dir != 0:
		_sprite_face(dir)
		velocity.y = _accelerate(delta, velocity.y, dir, max_climbing_speed, climbing_acceleration, climbing_turnaround_acceleration)
	else:
		velocity.y = _decelerate(delta, velocity.y, climbing_deceleration)

func _process_perched():
	velocity = Vector2.ZERO
	_climbing_rubber_band()

	if Input.is_action_pressed("jump"):
		_ground_jump()
		return

	var dir = _input_direction_h()
	_sprite_face(dir)

	if Input.is_action_pressed("move_down"):
		position.y += perch_climb_boost
		change_state(State.CLIMBING)

func _process_holding(delta: float):
	if is_on_floor():
		_touched_ground()
		velocity.y = 0
	else:
		velocity.y += holding_gravity * delta
	
	var dir = _input_direction_h()
	if dir != 0:
		change_state(State.DRAGGING)
		_sprite_face(dir)
	
	if dir != 0 && abs(velocity.x) < max_dragging_speed:
		velocity.x = _accelerate(delta, velocity.x, facing_dir, max_dragging_speed, dragging_acceleration, dragging_turnaround_acceleration)
	else:
		velocity.x = _decelerate(delta, velocity.x, dragging_deceleration)

	match state:
		State.DRAGGING:
			if is_zero_approx(velocity.x):
				change_state(State.HOLDING)
			else:
				_sprite_set_rel_speed(velocity.x, max_dragging_speed, min_dragging_animation_speed)

func _adjust_positon():
	if (state == State.CLIMBING || state == State.PERCHED) && _climbing_on != null:
		_climbing_snap_position()

func _physics_process(delta: float) -> void:
	_check_interactions()
	match state:
		State.CLIMBING:
			_process_climbing(delta)
		State.STANDING, State.RUNNING:
			_process_on_ground(delta)
		State.JUMPING, State.RISING, State.FALLING, State.GLIDING:
			_process_in_air(delta)
		State.PERCHED:
			_process_perched()
		State.HOLDING, State.DRAGGING:
			_process_holding(delta)
			pass
	move_and_slide()
	_adjust_positon()


func _ready() -> void:
	sprite.animation_finished.connect(_play_next_animation)
	jump_input_window.wait_time = jump_max_hold_time
	jump_input_window.one_shot = true


func _on_hiding_area_area_entered(_area: Area2D) -> void:
	hiding = true


func _on_hiding_area_area_exited(_area: Area2D) -> void:
	hiding = false
