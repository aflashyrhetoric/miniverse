class_name Bullet
extends RigidBody2D

const HitSprite = preload("res://Weapons/HitEffect.tscn")

@onready var animation_player = $AnimationPlayer
@onready var floor_collision_area = $FloorCollisionArea

var direction := Vector2.ZERO

@onready var hitbox := $Hitbox
@onready var sprite := $Sprite2D
@onready var impact_hitbox := $ImpactHitbox
@onready var disappear_timer := $DisappearTimer

var _damage := 10


func _ready():
	set_as_top_level(true)
	look_at(get_global_mouse_position())


func _physics_process(_delta: float) -> void:
	if disappear_timer.get_time_left() == 0.0:
		pass


func destroy():
	animation_player.play("destroy")


func _on_FloorCollisionArea_body_entered(_tile_that_we_hit: Node) -> void:
	sprite.visible = false
	disappear_timer.start()
	var hit_sprite = HitSprite.instantiate()
	add_child(hit_sprite)
	hit_sprite.global_position = global_position
	hit_sprite.get_node("AnimationPlayer").play("hit")
