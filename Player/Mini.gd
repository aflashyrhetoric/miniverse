class_name Mini
extends Actor

var is_mini = true

# GAME CONSTANTS
const FLOOR_DETECT_DISTANCE = 2.0
const MAX_SPEED = Vector2(120, 600)

const JUMP_SPEED = 200.0
# const FALL_SPEED = 200.0

const SPEED_ACCEL_AIR = 20.0  # added per frame
const SPEED_ACCEL_GROUND = 5.0  # added per frame
const SPEED_DECAY_AIR = 0.8  # deducted per frame
const SPEED_DECAY_GROUND = 0.66  # deducted per frame

const AIR_STOMP_VELOCITY = Vector2(0, 800)
const TURN_SPEED_MULTIPLER = 3.95

const BUBBLE_DASH_VELOCITY = 240.0
const BUBBLE_DASH_FRAME_DURATION = 8

const DASH_VELOCITY = 200.0
const DASH_FRAME_DURATION = 8

const WALL_HOP_COUNTER_VELOCITY = Vector2(180, -160)
const WALL_SLIDE_FALL_SPEED = 50

const WALL_GRAB_CLIMB_VELOCITY = Vector2(0, -80)
const WALL_GRAB_FALL_VELOCITY = Vector2(0, 100)

## EXPORTED VARIABLES
export(float) var bubble_dash_particles_speed = BUBBLE_DASH_VELOCITY
#####################

onready var hazard_collision_shape = $HazardCollisionShape
onready var platform_detector = $PlatformDetector
onready var wall_grab_min_height_detector = $WallGrabDetector  # Must be a certain height above the ground to wall grab
onready var wall_grab_forward_detector = $WallGrabForwardDetector  # Must be a certain distance from the wall to grab
onready var animation_player = $AnimationPlayer
onready var shoot_timer = $ShootAnimation
onready var sprite = $AnimatedSprite

onready var level_boundary_trigger = $LevelBoundaryTrigger

onready var label = $Label

onready var gun = sprite.get_node(@"FlowerGun")

onready var ellie_float_range = $EllieFloatRange
onready var ellie_action_range = $EllieActionRange

# JUICE - AUDIO
onready var sound_jump = $Jump
# onready var sound_land = $Land
onready var footstep = $Footstep
onready var footstep_timer = $FootstepTimer
onready var sound_spawn = $SoundSpawn

# JUICE - DUST
onready var feet_position = $FeetPosition
onready var dust = $Dust

# JUICE - BUBBLES
onready var bubble_dash_particles = $BubbleDashParticles

# JUICE
onready var juice_animation_player = $JuiceAnimationPlayer

onready var coyote_timer = $CoyoteTimer
var _was_on_floor: bool

# Instance Variables
var _is_dying = false
var _is_inside_bubble = false

var _has_dash = true
var _is_dashing = false
var _should_refresh_dash_on_land = false
var _frames_since_started_dashing := 0

var _is_bubble_dashing = false
var _just_bubble_dashed = false
var _frames_since_started_bubble_dashing := 0
var _bubble_origin: Vector2 = Vector2.ZERO
var _is_air_stomping = false
var _has_jumped = false
var _has_extra_jump = false
var _has_bubble_dash_jump = false

# Ellie
var _is_within_ellie_action_range = true

# Physics-pause, used for transitioning rooms
var _pause_movement = false
var _just_unpaused = false
var _pre_pause_velocity: Vector2 = Vector2.ZERO


func _ready():
	hazard_collision_shape.connect("body_entered", self, "begin_dying")
	Events.connect("mini_entered_bubble", self, "grant_extra_jump")
	Events.connect("mini_should_die", self, "begin_dying")
	Events.connect("mini_died", self, "handle_death")

	# Ellie-events
	Events.connect("ellie_entered_action_range", self, "enable_ellie_action_range")
	Events.connect("ellie_exited_action_range", self, "disable_ellie_action_range")

	dust.lifetime = WorldVars.DUST_LIFETIME

	ellie_float_range.connect("body_entered", self, "_on_EllieFloatRange_body_entered")
	ellie_float_range.connect("body_exited", self, "_on_EllieFloatRange_body_exited")


func _process(_delta: float) -> void:
	if not is_on_floor() and _was_on_floor:
		coyote_timer.start()

	# stop the timer if it's running
	if is_on_floor() and not coyote_timer.is_stopped():
		coyote_timer.stop()

	animate_scale()
	########## KEEEEEEEEEEEEP LAST
	_was_on_floor = is_on_floor()


func _physics_process(_delta):
	var psn = owner.get_node("Ellie").global_position

	# label.text = str(psn, "\n", WorldVars.nearest_interaction_point)
	if _is_dying:
		return

	if _is_inside_bubble:
		_is_air_stomping = false

	if is_on_floor():
		if _has_jumped:
			Events.emit_signal("mini_landed", [feet_position.global_position])
		_has_jumped = false
		_is_air_stomping = false

		if _has_extra_jump:
			_has_extra_jump = false
		if _is_air_stomping:
			_is_air_stomping = false

		if _should_refresh_dash_on_land:
			refresh_dash()
			end_dash()

	var direction: Vector2 = get_direction()
	var dampen_second_jump_from_interrupted_jump: bool
	dampen_second_jump_from_interrupted_jump = (
		not _is_bubble_dashing
		and Input.is_action_just_released("jump")
		and _velocity.y < 0.0
	)

	_velocity = calculate_move_velocity(
		_velocity, direction, dampen_second_jump_from_interrupted_jump
	)

	if not Util.float_is_zero(_velocity.x, 0.01):
		if abs(_velocity.x) > 25.0:
			dust.emitting = true
			if footstep_timer.is_stopped() and not footstep.playing and is_on_floor():
				footstep.play()
				footstep_timer.start()
		else:
			dust.emitting = false
	else:
		dust.emitting = false
		footstep.stop()
		footstep_timer.stop()

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

	play_correct_animation()


func grant_extra_jump():
	_has_extra_jump = true


func grant_bubble_dash_jump():
	_has_bubble_dash_jump = true


func turn_sprites(direction, sprites_to_turn):
	for _sprite in sprites_to_turn:
		if direction.x != 0:
			if direction.x > 0:
				_sprite.scale.x = 1
			else:
				_sprite.scale.x = -1


func is_dashing() -> bool:
	return _is_bubble_dashing or _is_dashing


# Check if a jump is allowed on the current frame.
# ! DOES NOT INCLUDE bubble_dash permissions!
func allowed_to_jump() -> bool:
	if is_dashing() and _frames_since_started_dashing <= DASH_FRAME_DURATION:
		return false

	return (
		(is_on_floor() and not is_dashing())
		or (not is_on_floor() and not coyote_timer.is_stopped())
		or _has_extra_jump
		or _has_bubble_dash_jump
		or wall_grab_forward_detector.is_colliding()
	)


func allowed_to_dash() -> bool:
	return _has_dash and (not is_dashing()) and not _is_inside_bubble


# Check if a jump is allowed on the current frame.
# ! DOES NOT INCLUDE bubble_dash permissions!
func allowed_to_grab() -> bool:
	return wall_grab_forward_detector.is_colliding()


# Returns a value from -1 to 0, float, representing strength of player input on x-axis
func get_direction_x():
	# TODO - ADD BACK WALL HOP
	if (
		wall_grab_forward_detector.is_colliding()
		and Input.is_action_just_pressed("jump")
		and not wall_grab_min_height_detector.is_colliding()
	):
		if sprite.scale.x > 0:
			return -1
		else:
			return 1

	return Input.get_action_strength("move_right") - Input.get_action_strength("move_left")


# Returns a value from -1 to 0, float, representing strength of player input on y-axis
func get_direction_y() -> float:
	return Input.get_action_strength("move_down") - Input.get_action_strength("move_up")


# Returns a direction
func get_direction() -> Vector2:
	var dash_is_permitted = allowed_to_dash()
	var just_entered_dash_input = Input.is_action_just_pressed("dash")

	var jump_is_permitted = allowed_to_jump()
	var just_entered_jump_input = Input.is_action_just_pressed("jump")
	var should_jump_this_frame = (
		false
		if just_entered_dash_input
		else Input.is_action_just_pressed("jump")
	)

	# DO JUMP RELATED JUICE
	if jump_is_permitted and should_jump_this_frame:
		sound_jump.play()
		_has_jumped = true

	var direction_y = 0
	if jump_is_permitted and should_jump_this_frame:
		direction_y = -1

	if not should_jump_this_frame and not is_on_floor():
		direction_y = 1

	if _is_bubble_dashing:
		direction_y = _velocity.y

	var direction = Vector2(get_direction_x(), direction_y)
	if should_jump_this_frame:
		if _has_extra_jump:
			_has_extra_jump = false

		# The first jump after a bubble dash should be permitted
		if _just_bubble_dashed:
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


func refresh_dash():
	print("dash reset")
	_has_dash = true  # reset on landing
	_should_refresh_dash_on_land = false


func end_dash():
	print("end dashing")
	enable_gravity()
	# _has_dash = true # reset on landing
	_is_dashing = false
	# _should_refresh_dash_on_land = true
	_frames_since_started_dashing = 0


func end_bubble_dash():
	enable_gravity()
	bubble_dash_particles.emitting = false
	_is_bubble_dashing = false
	_just_bubble_dashed = true
	_frames_since_started_bubble_dashing = 0
	_bubble_origin = Vector2.ZERO


# Dashes should end when we hit something, regardless of the type of dash
func should_end_dash() -> bool:
	return is_on_floor() or is_on_wall() or is_on_ceiling()


# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
	current_linear_velocity: Vector2,
	player_input_direction: Vector2,
	dampen_second_jump_from_interrupted_jump: bool
):
	##########################
	# FOR CAMERA TRANSITIONS #
	##########################
	if _pause_movement:
		return Vector2(0, 0)
	elif _just_unpaused:
		_just_unpaused = false
		var _temp = _pre_pause_velocity
		_pre_pause_velocity = Vector2.ZERO
		return _temp

	################
	# UTILITY VARS #
	################
	var velocity = current_linear_velocity
	var x_direction_int = sprite.scale.x
	var x_direction = get_direction_x()
	var y_direction = get_direction_y()

	############################
	# BEGIN MOVEMENT HIERARCHY #
	############################
	if Input.is_action_pressed("wall_grab") and allowed_to_grab():
		# If holding both directions for some reason, return neither.
		if Input.is_action_pressed("move_up") and Input.is_action_pressed("move_down"):
			return Vector2(0, 0)

		if Input.is_action_pressed("move_up"):
			return WALL_GRAB_CLIMB_VELOCITY

		if Input.is_action_pressed("move_down"):
			return WALL_GRAB_FALL_VELOCITY

		# Wall Hop
		if wall_grab_forward_detector.is_colliding():
			if Input.is_action_just_pressed("jump"):
				velocity = Vector2(
					sprite.scale.x * -1 * WALL_HOP_COUNTER_VELOCITY.x, WALL_HOP_COUNTER_VELOCITY.y
				)
				# Do nothing but wallhop for now
				return velocity

		return Vector2(0, 0)

	# Wall Hop
	if (
		wall_grab_forward_detector.is_colliding()
		and not is_on_floor()
		and (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"))
	):
		if Input.is_action_just_pressed("jump"):
			velocity = Vector2(
				sprite.scale.x * -1 * WALL_HOP_COUNTER_VELOCITY.x, WALL_HOP_COUNTER_VELOCITY.y
			)
			# Do nothing but wallhop for now
			return velocity

	# Bubble-physics is a high-hierarchy operation, so check first
	if _is_bubble_dashing:
		_frames_since_started_bubble_dashing += 1

		if should_end_dash():
			end_bubble_dash()

		if _frames_since_started_bubble_dashing <= BUBBLE_DASH_FRAME_DURATION:
			return current_linear_velocity

		# Bubble dash is over
		end_bubble_dash()

		# Only grant bubble dash jump if they reached the full extent of the dash
		grant_bubble_dash_jump()

	if _is_dashing:
		_frames_since_started_dashing += 1
		print(_velocity)

		if should_end_dash():
			print("hit a floor or wall")
			end_dash()

		if _frames_since_started_dashing <= DASH_FRAME_DURATION:
			return current_linear_velocity

		# Dash is over
		end_dash()

	################
	# REGULAR DASH #
	################
	if allowed_to_dash() and Input.is_action_just_pressed("dash"):
		disable_gravity()
		_is_dashing = true
		_has_dash = false
		_should_refresh_dash_on_land = true

		var planned_direction := Vector2(stepify(x_direction, 0.5), stepify(y_direction, 0.5))
		# Dash straight forward if there's no given direction
		var direction_to_dash := (
			planned_direction
			if planned_direction != Vector2.ZERO
			else Vector2(x_direction_int, 0)
		)

		var new_velocity = direction_to_dash.normalized() * DASH_VELOCITY
		print(new_velocity)
		return new_velocity

	###############
	# BUBBLE DASH #
	###############
	if _is_inside_bubble:
		var just_jumped = Input.is_action_just_pressed("jump")
		if just_jumped:
			_is_bubble_dashing = true
			disable_gravity()

			var planned_direction := Vector2(stepify(x_direction, 0.5), stepify(y_direction, 0.5))
			# Dash straight forward if there's no given direction
			var direction_to_dash := (
				planned_direction
				if planned_direction != Vector2.ZERO
				else Vector2(x_direction_int, 0)
			)

			var new_velocity = direction_to_dash.normalized() * BUBBLE_DASH_VELOCITY

			# #########################
			# Takes care of some juice!
			# #########################

			# Configure bubble particles
			if not bubble_dash_particles.emitting:
				bubble_dash_particles.emitting = true
				var direction_from_mini_to_bubble_she_left = new_velocity.normalized() * -1

				# Configure the "material" resource's gravity to get it to move
				bubble_dash_particles.process_material.gravity = (
					Vector3(
						stepify(direction_from_mini_to_bubble_she_left.x, 1.0),
						stepify(direction_from_mini_to_bubble_she_left.y, 1.0),
						0
					)
					* bubble_dash_particles_speed
				)

			# Return the bubble_dash_velocity
			return new_velocity

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
		var accel := SPEED_ACCEL_GROUND if is_on_floor() else SPEED_ACCEL_AIR

		#	If we're turning around, we have to subtract from the velocity,
		# but lets do it quickly with a multiplier, and only if we're grounded
		if (
			opposite_directions(player_input_direction.x, current_linear_velocity.x)
			and is_on_floor()
		):
			accel *= TURN_SPEED_MULTIPLER

		var increased_speed_x = current_linear_velocity.x + accel * x_direction_int
		# If we're going to go faster than our max, cap horizontal speed
		velocity.x = (
			increased_speed_x
			if abs(increased_speed_x) < MAX_SPEED.x
			else MAX_SPEED.x * x_direction_int
		)
	else:
		var reduced_speed_x: float = (
			current_linear_velocity.x
			* (SPEED_DECAY_GROUND if is_on_floor() and not is_dashing() else SPEED_DECAY_AIR)
		)
		# We can't exceed x max speed while no inputs are pressed
		if abs(reduced_speed_x) < 3:
			velocity.x = 0
		else:
			velocity.x = reduced_speed_x

	# If jumping
	if player_input_direction.y == -1 and not _just_bubble_dashed:
		velocity.y = JUMP_SPEED * player_input_direction.y  # velocity.y will always be negative, it's not being multiplied by itself

	# If falling:
	if velocity.y > 0 and not _is_air_stomping:
		if velocity.y > MAX_SPEED.y:
			velocity.y = MAX_SPEED.y

	if dampen_second_jump_from_interrupted_jump:
		# Decrease the Y velocity by multiplying it, but don't set it to 0
		# as to not be too abrupt.
		velocity.y *= 0.4

	if is_wall_sliding(velocity):
		velocity.y = WALL_SLIDE_FALL_SPEED
	return velocity


func is_wall_sliding(_v: Vector2) -> bool:
	return (
		wall_grab_forward_detector.is_colliding()  # Must be close to the wall
		and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))  # Must be pressing L/R to express intent
		and not Input.is_action_just_pressed("jump")  # Not jumping
		and not wall_grab_min_height_detector.is_colliding()  # Must be a minimum distance from the ground
		and _v.y > 0
	)  # Only if user is currently falling, so we don't wall grab on the way up


enum SCALE_STATE { BASE, JUMPING, LANDING }


func animate_scale():
	return
	if not _is_bubble_dashing and (Input.is_action_just_pressed("jump")):
		scale = Vector2(0.80, 1.10)

	if is_on_floor():
		if not _was_on_floor:
			scale = Vector2(1.10, .90)
			return

		if not _is_inside_bubble and not is_wall_sliding(_velocity) and scale != Vector2(1, 1):
			scale = lerp(scale, Vector2(1, 1), 0.2)

	if _is_inside_bubble:
		scale = lerp(scale, Vector2(1, 1), 0.2)


func play_correct_animation():
	if is_on_floor():
		if abs(_velocity.x) > 0.1:
			sprite.animation = "run"
		else:
			sprite.animation = "idle"
	else:
		if _velocity.y < 0:
			sprite.animation = "jump_up"
		if _velocity.y > 0:
			sprite.animation = "jump_down"


func _on_EllieFloatRange_body_entered(_body: Node) -> void:
	Events.emit_signal("ellie_entered_area")


func _on_EllieFloatRange_body_exited(_body: Node) -> void:
	Events.emit_signal("ellie_exited_area")


func begin_dying(_body):
	# Indicate death, and send along the position of death (so we can calculate nearest respawn)
	_is_dying = true
	sprite.playing = false
	animation_player.play("dying")
	print("before animation")
	yield(animation_player, "animation_finished")
	print("after animation")
	send_death_signal(_body)


func send_death_signal(_body):
	# Indicate death, and send along the position of death (so we can calculate nearest respawn)
	Events.emit_signal("mini_died", _body)


# Alias for easy external use
func handle_death(_body):
	_velocity = Vector2.ZERO
	sound_spawn.play()
	reset_state_variables()


func reset_state_variables():
	reset_death_orchestration_variables()
	reset_sprite_variables()
	reset_movement_variables()
	reset_bubble_variables()


func reset_death_orchestration_variables():
	_is_dying = false


func reset_sprite_variables():
	print("reset")
	sprite.offset = Vector2(0, 0)
	sprite.animation = "idle"


func reset_movement_variables():
	enable_gravity()
	_is_air_stomping = false
	_has_jumped = false
	_has_extra_jump = false


func reset_bubble_variables():
	_is_inside_bubble = false
	_is_bubble_dashing = false
	_has_bubble_dash_jump = false
	bubble_dash_particles.emitting = false
	_frames_since_started_bubble_dashing = 0
	_bubble_origin = Vector2.ZERO


func enter_bubble(bubble_origin: Vector2):
	if _is_bubble_dashing:
		end_bubble_dash()
	_is_inside_bubble = true
	_bubble_origin = bubble_origin
	_has_extra_jump = false


func exit_bubble():
	_is_inside_bubble = false


func enable_ellie_action_range(_body) -> void:
	_is_within_ellie_action_range = true


func disable_ellie_action_range(_body) -> void:
	_is_within_ellie_action_range = false
