extends CharacterBody2D


enum directions {
	RIGHT = 1,
	LEFT = -1
}

@export var gravity = 981.0
@export var base_speed = 10.0
@export var chase_speed_mult = 1.5
@export var facing_direction = directions.RIGHT
var detection_progress = 0.0
var has_treat = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var treat = Treat.create(randi() % len(Treat.Type))
	$body/TreatHolder.add_child(treat)
	has_treat = true
	
func _process(delta: float) -> void:
	$body.scale.x = facing_direction
	if $body/TreatHolder.get_child_count() == 0:
		has_treat = false
	else:
		has_treat = true

func _physics_process(delta: float) -> void:
	if not $body/floorRay.get_collider():
		velocity.y += gravity * delta
	move_and_slide()
		
func move(speed: float):
	velocity.x = speed * facing_direction

func stop_moving():
	velocity.x = 0

func turn_around():
	facing_direction *= -1
	
func can_see_player():
	var colliders = $body/SightArea.get_overlapping_bodies()
	if len(colliders) == 0:
		return false
	var collider: Player
	for c in colliders:
		if c is Player:
			collider = c
			break
			
	if not collider:
		return false
		
	if collider.hiding or not collider.can_be_detected:
		return false
	return true
	
func can_pickup_treat():
	if has_treat: return false
	var treat: DroppedTreat
	for collider in $CaptureArea.get_overlapping_bodies():
		if collider is DroppedTreat:
			treat = collider
			break
	if not treat: return false
	return treat

func turn_toward_player():
	if not can_see_player():
		return
	
	var player: Node2D = $body/SightArea.get_overlapping_bodies()[0]
	if player.global_position.x <= global_position.x:
		facing_direction = directions.LEFT
	else:
		facing_direction = directions.RIGHT

func set_sprite_state(state):
	$body/sprite.animation = state
		
func can_capture_player():
	var colliders = $CaptureArea.get_overlapping_bodies()
	
	if len(colliders) == 0:
		return false
	
	var player: Player = colliders[0]

	if not player.hiding:
		return true
	
	return false
	
func capture_player():
	if not can_capture_player():
		return
	
	$CaptureArea.get_overlapping_bodies()[0].respawn()
	Score.add_points(-500)
	


func pickup_treat():
	var treat: DroppedTreat = can_pickup_treat()
	if not treat: return
	var new_treat = Treat.create(treat._type)
	treat.queue_free()
	$body/TreatHolder.add_child(new_treat)
