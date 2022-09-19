class_name Ellie
extends Actor

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

onready var sprite = $Sprite

var _direction = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func died() -> void:
	pass

func _physics_process(delta):
	global_position = global_position + (_velocity * delta)
