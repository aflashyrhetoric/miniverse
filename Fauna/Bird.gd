class_name Bird
extends Fauna

export(Vector2) var fly_speed = Vector2.ZERO

onready var animation_player = $AnimationPlayer
onready var scare_radius = $ScareRadius
onready var disappear_timer = $DisappearTimer
onready var sprite = $Sprite
onready var flying_sprite = $FlyingSprite

onready var sound_flapping = $Flap


func _ready() -> void:
	animation_player.play("idle")
	flying_sprite.visible = false


func _physics_process(delta):
	if not _velocity == Vector2.ZERO:
		# print(global_position, _velocity)
		global_position = global_position + (_velocity * delta)


func _on_ScareRadius_body_entered(body: Node) -> void:
	disappear_timer.start()
	animation_player.play("flying")
	sprite.visible = false
	flying_sprite.visible = true
	sound_flapping.play()

	var direction = body.global_position.direction_to(global_position)
	_velocity = direction * fly_speed

	if direction.x < 0:
		sprite.scale.x *= 1
	else:
		sprite.scale.x *= -1

	pass  # Replace with function body.
