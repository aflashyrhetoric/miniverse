class_name Enemy
extends Actor

enum State {
	WALKING,
	DEAD,
}

enum Wall { LEFT, RIGHT }

var _state = State.WALKING

export(int) var max_health = 100
var _health = max_health

onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var left_wall_detector = $LeftWallDetector
onready var right_wall_detector = $RightWallDetector
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var hitbox = $Hitbox
onready var health_label = $HealthLabel

const HitSprite = preload("res://Weapons/HitEffect.tscn")

# If the sprite spawns facing right, it's as if it hit the left wall
onready var last_wall_hit: int = Wall.LEFT if sprite.scale.x > 0 else Wall.Right


func _ready():
	_velocity.x = speed.x


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
		sprite.scale.x = abs(sprite.scale.x)
	else:
		# If the sprite isn't facing left, make it face left. We can't set -1 directly bc the sprite scale is 3.
		if sprite.scale.x > 0:
			sprite.scale.x *= -1

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
	if _health <= 0:
		return "destroy"

	if _state == State.WALKING:
		if _velocity.x == 0:
			animation_new = "idle"
		else:
			animation_new = "walk"
	else:
		animation_new = "destroy"
	return animation_new


# When shot. Only bullets can hit, so no need to check the type of the entered body
func _on_Hitbox_body_entered(projectile: Node) -> void:
	_health -= projectile._damage
	health_label.text = str(_health)

	## Show Sprite
	var hit_sprite = HitSprite.instance()
	hit_sprite.global_position = projectile.global_position
	hit_sprite.get_node("AnimationPlayer").play("hit")
	hit_sprite.set_as_toplevel(true)
	projectile.queue_free()
	add_child(hit_sprite)
	print("enemy hit")
