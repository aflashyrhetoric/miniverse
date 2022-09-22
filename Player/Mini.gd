class_name Mini
extends Actor

# warning-ignore:unused_signal
# signal collect_coin

# signal mini_died

# signal ellie_entered_area
# signal ellie_exited_area

const FLOOR_DETECT_DISTANCE = 5.0
const MAX_SPEED = Vector2(120, 600)
const JUMP_SPEED = 250.0
const FALL_SPEED = 200.0
const WALK_ACCEL_AIR = 20  # added per frame
const WALK_ACCEL_GROUND = 5  # added per frame
const WALK_DECAY_AIR = 0.90  # multiplied per5frame
const WALK_DECAY_GROUND = 0.70  # multiplied per frame
const AIR_STOMP_VELOCITY = Vector2(0, 800)
const TURN_SPEED_MULTIPLER = 1.75

# const BUBBLE_FLY_TO_ORIGIN_SPEED = 200
const BUBBLE_DASH_VELOCITY = 200
const BUBBLE_DASH_FRAME_DURATION = 20

const WALL_HOP_COUNTER_VELOCITY = 300
const WALL_GRAB_FALL_SPEED = 50

## EXPORTED VARIABLES
# export(String) var action_suffix = ""
#####################

onready var hazard_collision_shape = $HazardCollisionShape
onready var platform_detector = $PlatformDetector
onready var wall_grab_detector = $WallGrabDetector  # Must be a certain height above the ground to wall grab
onready var wall_grab_forward_detector = $WallGrabForwardDetector  # Must be a certain distance from the wall to grab
onready var animation_player = $AnimationPlayer
onready var shoot_timer = $ShootAnimation
onready var sprite = $Sprite
onready var sound_jump = $Jump

onready var level_boundary_trigger = $LevelBoundaryTrigger

onready var label = $Label

onready var gun = sprite.get_node(@"FlowerGun")

onready var ellie_float_range = $EllieFloatRange

# JUICE
onready var juice_animation_player = $JuiceAnimationPlayer
onready var jump_dust = $JumpDust
onready var land_dust = $LandDust

# Instance Variables
var _is_inside_bubble = false
var _is_bubble_dashing = false
var _just_bubble_dashed = false
var _frames_since_started_bubble_dashing := 0
var _bubble_origin: Vector2 = Vector2.ZERO
var _is_air_stomping = false
var _has_jumped = false
var _has_extra_jump = false
var _has_bubble_dash_jump = false

# Physics-pause, used for transitioning rooms
var _pause_movement = false
var _just_unpaused = false
var _pre_pause_velocity: Vector2 = Vector2.ZERO


func _ready():
	hazard_collision_shape.connect("area_entered", self, "died")
	ellie_float_range.connect("body_entered", self, "_on_EllieFloatRange_body_entered")
	ellie_float_range.connect("body_exited", self, "_on_EllieFloatRange_body_exited")
	Events.connect("mini_entered_bubble", self, "grant_extra_jump")

func _physics_process(_delta):
	if _is_inside_bubble:
		_is_air_stomping = false

	if is_on_floor() and _has_jumped:
		# vars
		_has_jumped = false
		_is_air_stomping = false
		# bubble vars
		_just_bubble_dashed = false
		_is_bubble_dashing = false
		_has_bubble_dash_jump = false

		if _has_extra_jump:
			_has_extra_jump = false
		if _is_air_stomping:
			_is_air_stomping = false
		# anims
		juice_animation_player.play("land")
		# logging
		print("played land")
		# if platform_detector.get_collider()

	# Play jump sound
	#	if Input.is_action_just_pressed("jump") and is_on_floor():
	#		sound_jump.play()

	var direction: Vector2 = get_direction()
	var dampen_second_jump_from_interrupted_jump: bool
	dampen_second_jump_from_interrupted_jump = (
		not _is_bubble_dashing
		and Input.is_action_just_released("jump")
		and _velocity.y < 0.0
	)

	# Wall Hop
	if wall_grab_forward_detector.is_colliding():
		if _is_bubble_dashing:
			end_bubble_dash()
		if Input.is_action_just_pressed("jump"):
			_velocity.x = direction.x * WALL_HOP_COUNTER_VELOCITY
			print(_velocity.x, "just jumped")

	_velocity = calculate_move_velocity(
		_velocity, direction, dampen_second_jump_from_interrupted_jump
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
	if Input.is_action_just_pressed("shoot"):
		is_shooting = gun.shoot()

	var animation = get_new_animation(is_shooting)
	if animation != animation_player.current_animation and shoot_timer.is_stopped():
		if is_shooting:
			shoot_timer.start()
		animation_player.play(animation)


func grant_extra_jump():
	print("extra jump granted")
	_has_extra_jump = true


func grant_bubble_dash_jump():
	print("bubble dash jump granted")
	_has_bubble_dash_jump = true


func turn_sprites(direction, sprites_to_turn):
	for _sprite in sprites_to_turn:
		if direction.x != 0:
			if direction.x > 0:
				_sprite.scale.x = 1
			else:
				_sprite.scale.x = -1


# Check if a jump is allowed on the current frame.
# ! DOES NOT INCLUDE bubble_dash permissions!
func check_jump_permissions():
	return (
		is_on_floor()
		or _has_extra_jump
		or _has_bubble_dash_jump
		or wall_grab_forward_detector.is_colliding()
	)


# Returns a value from -1 to 0, float, representing strength of player input on x-axis
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

	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")


# Returns a value from -1 to 0, float, representing strength of player input on y-axis
func get_direction_y() -> float:
	return Input.get_action_strength("move_down") - Input.get_action_strength("move_up")


func get_direction() -> Vector2:
	var jump_is_permitted = check_jump_permissions()
	var just_jumped = Input.is_action_just_pressed("jump")

	# DO JUMP RELATED JUICE
	if jump_is_permitted and just_jumped:
		_has_jumped = true
		# juice_animation_player.play("jump")
		print("played jump")

	var direction_y = -1 if jump_is_permitted and just_jumped else 0
	if _is_bubble_dashing:
		direction_y = _velocity.y

	var direction = Vector2(get_direction_x(), direction_y)
	if just_jumped:
		if _has_extra_jump:
			_has_extra_jump = false

		# The first jump after a bubble dash should be permitted
		if _just_bubble_dashed:
			print("just used bubble dash jump")
			_just_bubble_dashed = false
			_has_bubble_dash_jump = false

	return direction


func pause_movement():
	_pause_movement = true
	_pre_pause_velocity = _velocity


func unpause_movement():
	_pause_movement = false
	_just_unpaused = true


func opposite_directions(a, b):
	if a < 0 and b > 0:
		return true
	if a > 0 and b < 0:
		return true
	return false


func end_bubble_dash():
	enable_gravity()
	_is_bubble_dashing = false
	_is_inside_bubble = false
	_just_bubble_dashed = true
	_frames_since_started_bubble_dashing = 0
	_bubble_origin = Vector2.ZERO


# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
	current_linear_velocity: Vector2,
	player_input_direction: Vector2,  # INPUT DIRECTION
	dampen_second_jump_from_interrupted_jump: bool
):
	if _pause_movement:
		return Vector2(0, 0)
	elif _just_unpaused:
		_just_unpaused = false
		var _temp = _pre_pause_velocity
		_pre_pause_velocity = Vector2.ZERO
		print("restoring velocity to: ", _pre_pause_velocity)
		return _temp

	var velocity = current_linear_velocity
	var x_direction_int = sprite.scale.x
	var x_direction = get_direction_x()
	var y_direction = get_direction_y()

	# Bubble-physics is a high-hierarchy operation
	if _is_bubble_dashing:
		_frames_since_started_bubble_dashing += 1

		if _frames_since_started_bubble_dashing <= BUBBLE_DASH_FRAME_DURATION:
			return current_linear_velocity

		# Bubble dash is over
		end_bubble_dash()
		# Only grant bubble dash jump if they reached the full extent of the dash
		grant_bubble_dash_jump()

	if _is_inside_bubble:
		var just_jumped = Input.is_action_just_pressed("jump")
		if just_jumped:
			_is_bubble_dashing = true
			disable_gravity()
			print("DASHING AT ANGLE:", x_direction, y_direction)
			var planned_direction := Vector2(x_direction, y_direction)
			# Dash straight forward if there's no given direction
			var direction_to_dash := (
				planned_direction
				if planned_direction != Vector2.ZERO
				else Vector2(x_direction_int, 0)
			)
			return direction_to_dash.normalized() * BUBBLE_DASH_VELOCITY

		if not just_jumped and not _is_bubble_dashing:
			if _bubble_origin != global_position:
				var distance_between_mini_and_bubble = (
					global_position.distance_to(_bubble_origin)
					* 10
				)
				var direction_from_mini_to_bubble_origin = global_position.direction_to(
					_bubble_origin
				)
				return distance_between_mini_and_bubble * direction_from_mini_to_bubble_origin
			else:
				return Vector2.ZERO  # If we're at the bubble_origin, don't move more

	# Air-stomping is next-highest in the hierarchy
	if (
		_is_air_stomping
		or (
			not is_on_floor()
			and not platform_detector.is_colliding()
			and Input.is_action_just_pressed("air_stomp")
		)
	):
		_is_air_stomping = true
		return AIR_STOMP_VELOCITY

	# COMPUTE X VELOCITY
	if player_input_direction.x != 0.0:
		var accel := 0.0

		if is_on_floor():
			accel = WALK_ACCEL_GROUND if player_input_direction.x == 1 else -WALK_ACCEL_GROUND
		else:
			accel = WALK_ACCEL_AIR if player_input_direction.x == 1 else -WALK_ACCEL_AIR

		#	If we're turning around, we have to subtract from the velocity,
		# but lets do it quickly with a multiplier, and only if we're grounded
		if (
			opposite_directions(player_input_direction.x, current_linear_velocity.x)
			and is_on_floor()
		):
			accel *= TURN_SPEED_MULTIPLER
			pass

		var would_be_speed_x = current_linear_velocity.x + accel  #* x_direction
		# If we're going to go faster than our max, cap horizontal speed
		velocity.x = (
			would_be_speed_x
			if abs(would_be_speed_x) < MAX_SPEED.x
			else MAX_SPEED.x * x_direction_int
		)
	else:
		var would_be_speed_x = (
			current_linear_velocity.x
			* (WALK_DECAY_GROUND if is_on_floor() else WALK_DECAY_AIR)
		)
		# if would_be_speed_x < 0:
		# 	would_be_speed_x = 0
		# We can't exceed x max speed while no inputs are pressed
		velocity.x = would_be_speed_x

	# If jumping
	if player_input_direction.y == -1 and not _just_bubble_dashed:
		print("hit a jump")
		velocity.y = JUMP_SPEED * player_input_direction.y  # velocity.y will always be negative, it's not being multiplied by itself

	# If falling:
	if velocity.y > 0 and not _is_air_stomping:
		# print("falling!!!", velocity)
		pass

	if dampen_second_jump_from_interrupted_jump:
		# Decrease the Y velocity by multiplying it, but don't set it to 0
		# as to not be too abrupt.
		velocity.y *= 0.4

	if is_wall_grabbing(velocity):
		print("reduced speed")
		velocity.y = WALL_GRAB_FALL_SPEED
	return velocity


func is_wall_grabbing(_v: Vector2) -> bool:
	return (
		wall_grab_forward_detector.is_colliding()  # Must be close to the wall
		and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))  # Must be pressing L/R to express intent
		and not Input.is_action_just_pressed("jump")  # Not jumping
		and not wall_grab_detector.is_colliding()  # Must be a minimum distance from the ground
		and _v.y > 0
	)  # Only if user is currently falling, so we don't wall grab on the way up


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
	Events.emit_signal("ellie_entered_area")


func _on_EllieFloatRange_body_exited(_body: Node) -> void:
	Events.emit_signal("ellie_exited_area")

func mini_died():
	emit_signal("mini_died")

func died():
	_is_inside_bubble = false
	_is_bubble_dashing = false
	_bubble_origin = Vector2.ZERO
	_is_air_stomping = false
	_has_jumped = false
	_has_extra_jump = true


func enter_bubble(bubble_origin: Vector2):
	_is_inside_bubble = true
	_bubble_origin = bubble_origin
	_has_extra_jump = false


func exit_bubble():
	_is_inside_bubble = false
	# _is_bubble_dashing = false
