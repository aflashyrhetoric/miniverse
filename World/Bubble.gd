extends Node2D

signal mini_entered_bubble
signal mini_exited_bubble

const ORB_FLIGHT_SPEED = 500

onready var orb = $OrbSprite
onready var orb_boundary_sprite = $OrbBoundary
onready var _original_orb_position: Vector2 = orb.global_position
onready var bubble_shape = $BubbleShape

onready var bubble_entry_sound = $BubbleEntry
onready var bubble_exit_sound = $BubbleExit
onready var bubble_activated_sound = $BubbleActivated

onready var label = $Label

onready var mini_placement = $MiniPlacement

export(bool) var _require_activation = false
var _should_disable = false
var _active = null

var _label
var _should_reset_orb_position = false


func _ready() -> void:
	add_to_group("bubbles")
	# Set up signals for the hook zone so we can detect mini entering
	bubble_shape.connect("body_entered", self, "_mini_entered")
	bubble_shape.connect("body_exited", self, "_mini_exited")

	Events.connect("mini_died", self, "handle_mini_death")
	Events.connect("mini_landed", self, "handle_mini_landed")

	# Get child nodes that we need

	if _require_activation:
		orb_boundary_sprite.visible = false
		_should_disable = true


func _process(_delta: float) -> void:
	# Disable the orb if we've hit mini once
	if _should_disable and _active:
		disable()
	elif not _should_disable and not _active:
		enable()

	label.text = str(_active)


func is_active() -> bool:
	if _require_activation:
		return _active

	return true


func handle_mini_death(_body):
	_should_disable = true


func handle_mini_landed(_body):
	# print(_body)
	pass


func _mini_entered(_mini):
	# Get a pointer to mini
	if not is_active():
		return

	_mini.enter_bubble(mini_placement.global_position)
	orb.visible = false
	orb_boundary_sprite.modulate.a = 0.2
	bubble_entry_sound.play()
	Events.emit_signal("mini_entered_bubble")


func _mini_exited(_mini):
	_mini.exit_bubble()
	if is_active():
		# Update the orchestration variables
		bubble_exit_sound.play()
		_should_reset_orb_position = true

		# Make the circle visible again
		orb.visible = true
		orb_boundary_sprite.modulate.a = 0.5

		# Restore the center orb's visibility and function
		_should_disable = false
		Events.emit_signal("mini_exited_bubble")
	else:
		disable()


func disable():
	_active = false
	if _require_activation:
		orb_boundary_sprite.visible = false
	else:
		orb_boundary_sprite.visible = true


func enable():
	bubble_activated_sound.play()
	_active = true
	orb.visible = true
	orb_boundary_sprite.visible = true
