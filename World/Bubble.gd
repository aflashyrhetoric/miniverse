extends Node2D

signal mini_entered_bubble
signal mini_exited_bubble

const ORB_FLIGHT_SPEED = 500

onready var orb = $Orb
onready var orb_boundary_sprite = $OrbBoundary
onready var _original_orb_position: Vector2 = orb.global_position
onready var bubble_shape = $BubbleShape
onready var orb_hit = $OrbHit
onready var bubble_entry_sound = $BubbleEntry
onready var bubble_exit_sound = $BubbleExit

onready var mini_placement = $MiniPlacement

export(bool) var _require_activation = false

var _label
var _should_reset_position = false
var _orb_boundary: Node = null
var _direction: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO

var _mini_ref = null

var _should_disable = false
var _disabled = false


func _ready() -> void:
	add_to_group("bubbles")
	# Set up signals for the hook zone so we can detect mini entering
	bubble_shape.connect("body_entered", self, "_mini_entered")
	bubble_shape.connect("body_exited", self, "_mini_exited")

	# Set up signals for the orb so we can detect the orb flying to mini
	orb.connect("body_entered", self, "_orb_hit_mini")

	# Get child nodes that we need
	_orb_boundary = get_node("OrbBoundary")
	_label = orb.get_node("Label")

	if _require_activation:
		orb_boundary_sprite.visible = false


func _process(_delta: float) -> void:
	# Disable the orb if we've hit mini once
	if _should_disable and not _disabled:
		disable()

	if not _should_disable and _disabled:
		enable()

	if _should_reset_position:
		orb.global_position = _original_orb_position
		_should_reset_position = false

	if not _should_reset_position and _mini_ref != null:
		_direction = orb.global_position.direction_to(_mini_ref.global_position)
		_velocity = (_direction * ORB_FLIGHT_SPEED)


func _physics_process(delta: float) -> void:
	orb.global_position += _velocity * delta


func _mini_entered(_mini):
	# Get a pointer to mini
	_mini_ref = _mini
	_mini_ref.enter_bubble(mini_placement.global_position)
	_orb_boundary.modulate.a = 0.2
	bubble_entry_sound.play()
	Events.emit_signal("mini_entered_bubble")


func _mini_exited(_mini):
	# Update the orchestration variables
	bubble_exit_sound.play()
	_should_reset_position = true
	_mini_ref.exit_bubble()
	_mini_ref = null
	_direction = Vector2.ZERO
	_velocity = Vector2.ZERO

	# Make the circle visible again
	_orb_boundary.modulate.a = 0.5

	# Restore the center orb's visibility and function
	_should_disable = false
	Events.emit_signal("mini_exited_bubble")


func _orb_hit_mini(_mini):
	orb_hit.play()
	_should_disable = true


func disable():
	print("disable")
	_disabled = true
	_direction = Vector2.ZERO
	_velocity = Vector2.ZERO
	orb.monitoring = false
	if _require_activation:
		orb_boundary_sprite.visible = false
		orb.visible = true
	else:
		orb_boundary_sprite.visible = true
		orb.visible = false


func enable():
	_disabled = false
	orb.visible = true
	orb.monitoring = true
	orb_boundary_sprite.visible = true
