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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
	

func _process(delta: float) -> void:
	$body.scale.x = facing_direction

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
	var collider: Player = colliders[0]
	if collider.hiding:
		return false
	return true

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
		
