extends Area2D


# THIS FILE IS CALLED BY THE ELLIEACTIONRANGE NODE IN HERO.TSCN

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", Callable(self, "enable_ellie_action_range"))
	connect("body_exited", Callable(self, "disable_ellie_action_range"))


func enable_ellie_action_range(_action_point):
	WorldVars.nearest_interaction_point = _action_point
	Events.emit_signal("ellie_entered_action_range", _action_point.owner)


func disable_ellie_action_range(_action_point):
	Events.emit_signal("ellie_exited_action_range", _action_point.owner)
