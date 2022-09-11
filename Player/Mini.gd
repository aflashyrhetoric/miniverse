class_name Mini
extends Actor

# warning-ignore:unused_signal
signal collect_coin

signal ellie_entered_area
signal ellie_exited_area

const FLOOR_DETECT_DISTANCE = 50.0
const WALK_SPEED = 200
const WALK_ACCEL = WALK_SPEED / 20
const WALK_DECAY = WALK_SPEED / 20

## EXPORTED VARIABLES
export(String) var action_suffix = ""
#####################

onready var platform_detector = $PlatformDetector
onready var animation_player = $AnimationPlayer
onready var shoot_timer = $ShootAnimation
onready var sprite = $Sprite
onready var sound_jump = $Jump
onready var label = $Label
onready var gun = sprite.get_node(@"FlowerGun")
onready var ellie_float_range = $EllieFloatRange


func _ready():
	pass
	# Static types are necessary here to avoid warnings.


func _physics_process(_delta):
	# Play jump sound
#	if Input.is_action_just_pressed("jump" + action_suffix) and is_on_floor():
#		sound_jump.play()
	var direction = get_direction()
	var is_jump_interrupted: bool
	is_jump_interrupted = (
		Input.is_action_just_released("jump" + action_suffix)
		and _velocity.y < 0.0
	)
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)

	var snap_vector = Vector2.ZERO
	if direction.y == 0.0:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	var is_on_platform = platform_detector.is_colliding()

	####################### MOVE!!!
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4, 0.9, false
	)
	###############################

	# Change mini sprite direction
	turn_sprites(direction, [ellie_float_range, sprite])

	# We use the sprite's scale to store Robi’s look direction which allows us to shoot
	# bullets forward.
	# There are many situations like these where you can reuse existing properties instead of
	# creating new variables.
	var is_shooting = false
	if Input.is_action_just_pressed("shoot" + action_suffix):
		is_shooting = gun.shoot()

	var animation = get_new_animation(is_shooting)
	if animation != animation_player.current_animation and shoot_timer.is_stopped():
		if is_shooting:
			shoot_timer.start()
		animation_player.play(animation)


func turn_sprites(direction, sprites_to_turn):
	for _sprite in sprites_to_turn:
		if direction.x != 0:
			if direction.x > 0:
				_sprite.scale.x = 1
			else:
				_sprite.scale.x = -1


func get_direction():
	return Vector2(
		(
			Input.get_action_strength("move_right" + action_suffix)
			- Input.get_action_strength("move_left" + action_suffix)
		),
		-1 if is_on_floor() and Input.is_action_just_pressed("jump" + action_suffix) else 0
	)


# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
	current_linear_velocity: Vector2,
	direction: Vector2,
	speed_setting: Vector2,
	is_jump_interrupted: bool
):
	var velocity = current_linear_velocity

	if direction.x != 0.0:
		var would_be_speed_x = (abs(current_linear_velocity.x) + WALK_ACCEL) * direction.x
		# If we're going to go faster than our max, cap horizontal speed
		velocity.x = (
			would_be_speed_x
			if abs(would_be_speed_x) < max_speed.x
			else max_speed.x * direction.x
		)
	else:
		velocity.x = 0
		var would_be_speed_x = (abs(current_linear_velocity.x) + WALK_DECAY) * direction.x
		# If we're going to go faster than our max, cap horizontal speed
		velocity.x = (
			would_be_speed_x
			if abs(would_be_speed_x) < max_speed.x
			else max_speed.x * direction.x
		)

	if direction.y != 0.0:
		velocity.y = speed_setting.y * direction.y
	if is_jump_interrupted:
		# Decrease the Y velocity by multiplying it, but don't set it to 0
		# as to not be too abrupt.
		velocity.y *= 0.6
	return velocity


func get_new_animation(is_shooting = false):
	var animation_new = ""
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			animation_new = "run"
		else:
			animation_new = "idle"
	else:
		if _velocity.y > 0:
			animation_new = "falling"
		else:
			animation_new = "jumping"
	if is_shooting:
		animation_new += "_weapon"
	return animation_new


func _on_EllieFloatRange_body_entered(_body: Node) -> void:
	emit_signal("ellie_entered_area")


func _on_EllieFloatRange_body_exited(_body: Node) -> void:
	emit_signal("ellie_exited_area")
