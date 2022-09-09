class_name Enemy
extends Actor

enum State {
	WALKING,
	DEAD,
}

enum Wall { LEFT, RIGHT }

var _state = State.WALKING

# onready var platform_detector = $PlatformDetector
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var left_wall_detector = $LeftWallDetector
onready var right_wall_detector = $RightWallDetector
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer

# If the sprite spawns facing right, it's as if it hit the left wall
onready var last_wall_hit: int = Wall.LEFT if sprite.scale.x == 1 else Wall.Right


# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():
	_velocity.x = speed.x


# Physics process is a built-in loop in Godot.
# If you define _physics_process on a node, Godot will call it every frame.

# At a glance, you can see that the physics process loop:
# 1. Calculates the move velocity.
# 2. Moves the character.
# 3. Updates the sprite direction.
# 4. Updates the animation.


# Splitting the physics process logic into functions not only makes it
# easier to read, it help to change or improve the code later on:
# - If you need to change a calculation, you can use Go To -> Function
#   (Ctrl Alt F) to quickly jump to the corresponding function.
# - If you split the character into a state machine or more advanced pattern,
#   you can easily move individual functions.
func _physics_process(_delta):
	var collision_exists = left_wall_detector.is_colliding() or right_wall_detector.is_colliding()

	# If the enemy encounters a wall or an edge, the horizontal velocity is flipped.
	if not floor_detector_left.is_colliding() and not collision_exists:
		_velocity.x = speed.x
	elif not floor_detector_right.is_colliding() and not collision_exists:
		_velocity.x = -speed.x

	# Alternate direction when the wall is hit
	if collision_exists:
		handle_wall_hit()

	# We only update the y value of _velocity as we want to handle the horizontal movement ourselves.
	_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y

	# We flip the Sprite depending on which way the enemy is moving.
	if _velocity.x > 0:
		sprite.scale.x = 1
	else:
		sprite.scale.x = -1

	var animation = get_new_animation()
	if animation != animation_player.current_animation:
		animation_player.play(animation)


func handle_wall_hit():
	if is_on_wall():
		_velocity.x = _velocity.x * -1


func destroy():
	_state = State.DEAD
	_velocity = Vector2.ZERO


func get_new_animation():
	var animation_new = ""
	if _state == State.WALKING:
		if _velocity.x == 0:
			animation_new = "idle"
		else:
			animation_new = "walk"
	else:
		animation_new = "destroy"
	return animation_new
