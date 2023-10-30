extends Node2D

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

@onready var interactivity_range = $InteractivityRange
@onready var key_to_press_label = $KeyToPressLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactivity_range.connect("body_entered", Callable(self, "handle_mini_entered"))
	interactivity_range.connect("body_exited", Callable(self, "handle_mini_exited"))


func handle_mini_entered(_body: Node):
	print('mini entered')
	key_to_press_label.visible = true


func handle_mini_exited(_body: Node):
	print('mini exited')
	key_to_press_label.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
