class_name Actor
extends KinematicBody2D

# Both the Player and Enemy inherit this scene as they have shared behaviours
# such as speed and are affected by gravity.

# A magnitude vector
# export var speed = Vector2(150.0, 200.0)

onready var gravity = ProjectSettings.get("physics/2d/default_gravity")

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO

var _gravity_enabled := true


# _physics_process is called after the inherited _physics_process function.
# This allows the Player and Enemy scenes to be affected by gravity.
func _physics_process(delta):
	if _gravity_enabled:
		_velocity.y += gravity * delta


func enable_gravity():
	_gravity_enabled = true


func disable_gravity():
	_gravity_enabled = false


func die(animation_player: AnimationPlayer = null):
	if (
		animation_player != null
		and animation_player.has_animation("destroy")
		and animation_player.current_animation != "destroy"
	):
		print(animation_player.current_animation)
		animation_player.play("destroy")
	else:
		queue_free()
