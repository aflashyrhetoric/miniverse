class_name ActorFlying
extends KinematicBody2D

# Both the Player and Enemy inherit this scene as they have shared behaviours
# such as speed and are affected by gravity.


export var speed = Vector2(0, 350.0)
export var max_speed = Vector2(220, 600)

# onready var gravity = ProjectSettings.get("physics/2d/default_gravity")

const FLOOR_NORMAL = Vector2.UP

var _velocity = Vector2.ZERO

func die_if_low(_health):
	if _health <= 0:
		queue_free()

