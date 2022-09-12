class_name Bullet
extends RigidBody2D

const HitSprite = preload("res://Weapons/HitEffect.tscn")

onready var animation_player = $AnimationPlayer
onready var floor_collision_area = $FloorCollisionArea

var direction := Vector2.ZERO

onready var hitbox := $Hitbox
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


func _on_FloorCollisionArea_body_entered(_tile_that_we_hit: Node) -> void:
	var hit_sprite = HitSprite.instance()
	hit_sprite.global_position = global_position
	hit_sprite.set_as_toplevel(true)
	hit_sprite.get_node("AnimationPlayer").play("hit")
	add_child(hit_sprite)
	queue_free()	
