extends Node2D

onready var hook_zone = $HookZone

signal mini_entered_hookzone
signal mini_exited_hookzone


func _ready() -> void:
	print("Initializing hook zone")
	print(hook_zone)
	hook_zone.connect("body_entered", self, "_mini_entered")
	hook_zone.connect("body_exited", self, "mini_exited")


func _mini_entered(_body):
	emit_signal("mini_entered_hookzone")
	print("mini_entered_hookzone")


func mini_exited(_body):
	emit_signal("mini_exited_hookzone")
	print("mini_exited_hookzone")
