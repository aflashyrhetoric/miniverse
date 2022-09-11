extends Node2D

signal mini_entered
signal mini_exited


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_HookZone_body_entered(_body:Node) -> void:
	emit_signal("mini_entered")


func _on_HookZone_body_exited(_body:Node) -> void:
	emit_signal("mini_exited")
