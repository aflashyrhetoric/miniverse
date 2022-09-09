class_name Gun
extends Position2D
# Represents a weapon that spawns and shoots bullets.
# The Cooldown timer controls the cooldown duration between shots.

export var bullet_velocity = 500.0
const Bullet = preload("res://Objects/Bullet.tscn")

onready var sound_shoot = $Shoot
onready var timer = $Cooldown


# ! THIS METHOD IS ONLY CALLED BY PLAYER.GD.
func shoot():
	if not timer.is_stopped():
		return false
	var bullet = Bullet.instance()
	bullet.global_position = global_position
	var direction_to_fire: Vector2 = (get_global_mouse_position() - global_position).normalized()
	print(direction_to_fire)
	bullet.linear_velocity = direction_to_fire * bullet_velocity

	bullet.set_as_toplevel(true)
	bullet.look_at(position + direction_to_fire)
	add_child(bullet)
	sound_shoot.play()
	timer.start()
	return true
