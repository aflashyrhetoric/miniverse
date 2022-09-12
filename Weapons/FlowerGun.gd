class_name FlowerGun
extends Gun

const Bullet = preload("res://Objects/Bullet.tscn")

onready var timer = $Cooldown
onready var sound_shoot = $Shoot
onready var bullet_spawn_point = $BulletSpawnPoint
onready var animation_player = $AnimationPlayer


# ! THIS METHOD IS ONLY CALLED BY PLAYER.GD.
func add_new_bullet():
	var bullet = Bullet.instance()
	bullet.set_as_toplevel(true)
	bullet.global_position = bullet_spawn_point.global_position
	bullet._damage = bullet_damage
	add_child(bullet)

	# Position
	var direction_to_fire: Vector2 = (get_global_mouse_position() - global_position).normalized()
	bullet.look_at(position + direction_to_fire)
	bullet.linear_velocity = direction_to_fire * bullet_velocity


func shoot():
	if not timer.is_stopped():
		return false

	add_new_bullet()

	animation_player.play("shoot")
	# sound_shoot.play()
	timer.start()
