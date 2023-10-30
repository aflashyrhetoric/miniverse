extends Node2D

const Shard = preload("res://World/Shard.tscn")

var _velocity = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


func shard(spawn_pt, look_at_pt, movement_direction) -> Shard:
	var shard = Shard.instantiate()
	shard.global_position = spawn_pt

	if look_at_pt != null:
		shard.look_at(look_at_pt)

	shard._velocity = shard.SHARD_SPEED * movement_direction
	shard.set_as_top_level(true)
	return shard
