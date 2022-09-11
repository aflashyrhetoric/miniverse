class_name EnemyFlying
extends ActorFlying

enum State {
	WALKING,
	DEAD,
}

const HitSprite = preload("res://Weapons/HitEffect.tscn")

enum Wall { LEFT, RIGHT }

var _state = State.WALKING

export(int) var max_health = 100
var _health = max_health

# onready var platform_detector = $PlatformDetector
onready var left_wall_detector = $LeftWallDetector
onready var right_wall_detector = $RightWallDetector
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer
onready var hitbox = $Hitbox
onready var health_label = $HealthLabel

# If the sprite spawns facing right, it's as if it hit the left wall
onready var last_wall_hit: int = Wall.LEFT if sprite.scale.x == 1 else Wall.Right


# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():
	_velocity.x = speed.x


func _process(_delta) -> void:
	die_if_low(_health)


func _physics_process(_delta):
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
