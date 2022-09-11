extends Node2D

onready var respawn_point = $RespawnPoint
onready var out_of_bounds = $OutOfBounds
onready var player = $Player

var _should_respawn = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	print(player.global_position, respawn_point.global_position)
	if _should_respawn:
		player.position = respawn_point.position
		_should_respawn = false


func _on_OutOfBounds_body_entered(body: Node) -> void:
	_should_respawn = true
