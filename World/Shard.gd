class_name Shard
extends Node2D


onready var timer = $Timer

var _velocity = Vector2.ZERO

var SHARD_SPEED = 4.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	global_position += _velocity


func begin_to_disappear():
	timer.start()
	yield(timer, "timeout")
	queue_free()