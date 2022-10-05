extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", self, "enable_ellie_action_range")
	connect("body_exited", self, "disable_ellie_action_range")
	pass  # Replace with function body.


func enable_ellie_action_range(_body):
	Events.emit_signal("ellie_entered_action_range", _body)


func disable_ellie_action_range(_body):
	Events.emit_signal("ellie_exited_action_range", _body)
