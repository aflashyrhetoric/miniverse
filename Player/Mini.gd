class_name Mini
extends Actor

# warning-ignore:unused_signal
signal collect_coin

signal ellie_entered_area
signal ellie_exited_area

const FLOOR_DETECT_DISTANCE = 5.0
const WALK_SPEED = 200
const WALK_ACCEL = WALK_SPEED / 20
const WALK_DECAY = 0.95  # unit slowed down per frame
const WALL_HOP_COUNTER_VELOCITY = 300
const WALL_GRAB_FALL_SPEED = 50

## EXPORTED VARIABLES
export(String) var action_suffix = ""
#####################

onready var platform_detector = $PlatformDetector
onready var wall_grab_detector = $WallGrabDetector  # Must be a certain height above the ground to wall grab
onready var wall_grab_forward_detector = $WallGrabForwardDetector  # Must be a certain distance from the wall to grab
onready var animation_player = $AnimationPlayer
onready var shoot_timer = $ShootAnimation
onready var sprite = $Sprite
onready var sound_jump = $Jump
onready var label = $Label
onready var gun = sprite.get_node(@"FlowerGun")
onready var ellie_float_range = $EllieFloatRange

# Instance Variables
var _has_extra_jump = true


func _ready():
	pass
	# Static types are necessary here to avoid warnings.


func _physics_process(_delta):
	if is_on_floor() and _has_extra_jump:
		print("jump reset")
		_has_extra_jump = false

	# Play jump sound
	#	if Input.is_action_just_pressed("jump" + action_suffix) and is_on_floor():
	#		sound_jump.play()

	var direction: Vector2 = get_direction()
	var dampen_second_jump_from_interrupted_jump: bool
	dampen_second_jump_from_interrupted_jump = (
		Input.is_action_just_released("jump" + action_suffix)
		and _velocity.y < 0.0
	)

	if Input.is_action_just_pressed("jump") and wall_grab_forward_detector.is_colliding():
		_velocity.x = direction.x * WALL_HOP_COUNTER_VELOCITY
		print(_velocity.x, "just jumped")

	_velocity = calculate_move_velocity(
		_velocity, direction, speed, dampen_second_jump_from_interrupted_jump
	)

	var snap_vector = Vector2.ZERO
	if direction.y == 0.0:
		snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE
	var is_on_platform = platform_detector.is_colliding()

	####################### MOVE!!!
	# Move at _velocity,
	# and stay stuck to the ground as long as we're within snap_vector distance to the ground.
	# FLOOR_NORMAL is up,
	_velocity = move_and_slide_with_snap(
		_velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4, 0.9, false
	)
	###############################

	# Change mini sprite direction
	turn_sprites(direction, [ellie_float_range, sprite, wall_grab_forward_detector])

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


func grant_extra_jump():
	print("extra jump granted")
	_has_extra_jump = true


func turn_sprites(direction, sprites_to_turn):
	for _sprite in sprites_to_turn:
		if direction.x != 0:
			if direction.x > 0:
				_sprite.scale.x = 1
			else:
				_sprite.scale.x = -1


func check_jump_permissions():
	var permitted = is_on_floor() or _has_extra_jump or wall_grab_forward_detector.is_colliding()
	return permitted


func get_direction_x():
	if (
		wall_grab_forward_detector.is_colliding()
		and Input.is_action_just_pressed("jump")
		and not wall_grab_detector.is_colliding()
	):
		if sprite.scale.x > 0:
			return -1
		else:
			return 1

	return (
		Input.get_action_strength("move_right" + action_suffix)
		- Input.get_action_strength("move_left" + action_suffix)
	)


func get_direction() -> Vector2:
	var jump_is_permitted = check_jump_permissions()
	var just_jumped = Input.is_action_just_pressed("jump" + action_suffix)
	var direction = Vector2(get_direction_x(), -1 if jump_is_permitted and just_jumped else 0)
	if just_jumped:
		_has_extra_jump = false

	return direction


func opposite_directions(a, b):
	if a < 0 and b > 0:
		return true
	if a > 0 and b < 0:
		return true
	return false


# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
	current_linear_velocity: Vector2,
	player_input_direction: Vector2,  # INPUT DIRECTION
	speed_setting: Vector2,
	dampen_second_jump_from_interrupted_jump: bool
):
	var velocity = current_linear_velocity
	var x_direction = -1 if player_input_direction.x < 0 else 1

	# COMPUTE X VELOCITY
	if player_input_direction.x != 0.0:
		var accel := 0.0
		print(player_input_direction.x, "||||", current_linear_velocity.x)

		# if player_input_direction.x == 1 and current_linear_velocity.x < 0:
		# 	accel = WALK_ACCEL
		# elif player_input_direction.x == -1 and current_linear_velocity.x > 0:
		# 	accel = -WALK_ACCEL
		# if player_input_direction.x == 1:
		# 	accel = WALK_ACCEL
		# if player_input_direction.x == 1:
		# 	accel = -WALK_ACCEL
		accel = WALK_ACCEL if player_input_direction.x == 1 else -WALK_ACCEL
		if opposite_directions(player_input_direction.x, current_linear_velocity.x):
			accel *= 1.25
			pass

		var would_be_speed_x = current_linear_velocity.x + accel  #* x_direction
		# If we're going to go faster than our max, cap horizontal speed
		velocity.x = (
			would_be_speed_x
			if abs(would_be_speed_x) < max_speed.x
			else max_speed.x * x_direction
		)
	else:
		var would_be_speed_x = current_linear_velocity.x * WALK_DECAY
		# if would_be_speed_x < 0:
		# 	would_be_speed_x = 0
		# We can't exceed x max speed while no inputs are pressed
		velocity.x = would_be_speed_x

	if player_input_direction.y != 0.0:
		velocity.y = speed_setting.y * player_input_direction.y
	if dampen_second_jump_from_interrupted_jump:
		# Decrease the Y velocity by multiplying it, but don't set it to 0
		# as to not be too abrupt.
		velocity.y *= 0.4

	if (
		wall_grab_forward_detector.is_colliding()
		and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_left"))
		and not Input.is_action_just_pressed("jump")
		and not wall_grab_detector.is_colliding()
	):
		velocity.y = WALL_GRAB_FALL_SPEED
	return velocity


func get_new_animation(_is_shooting = false):
	var animation_new = ""
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			animation_new = "run"
		else:
			animation_new = "idle"
	# else:
	# 	if _velocity.y > 0:
	# 		animation_new = "falling"
	# 	else:
	# 		animation_new = "jumping"
	# if is_shooting:
	# 	animation_new += "_weapon"
	return animation_new


func _on_EllieFloatRange_body_entered(_body: Node) -> void:
	emit_signal("ellie_entered_area")


func _on_EllieFloatRange_body_exited(_body: Node) -> void:
	emit_signal("ellie_exited_area")
