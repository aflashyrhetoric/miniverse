class_name Bullet
extends RigidBody2D

onready var animation_player = $AnimationPlayer

var direction := Vector2.ZERO

onready var hitbox := $hitbox
onready var sprite := $Sprite
onready var impact_hitbox := $ImpactHitbox

var _damage := 10

func _ready():
	set_as_toplevel(true)
	look_at(get_global_mouse_position())


# func _physics_process(_delta: float) -> void:
	# look_at(self.linear_velocity)

func destroy():
	animation_player.play("destroy")


func _on_body_entered(body):
	if body is Enemy:
		body.destroy()
