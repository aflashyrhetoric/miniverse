class_name Player
extends Node2D

## ELLIE CONSTANTS
const ELLIE_FLIGHT_SPEED = Vector2(50, 30)
const ELLIE_RETURN_SPEED = Vector2(10, 10)

# The BBs! :D
onready var mini = $Hero # TO DO FIX
onready var ellie = $Ellie

# Instance variables
var _ellie_is_inside_float_area = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.connect("ellie_entered_area", self, "_on_Mini_ellie_entered_area")
	Events.connect("ellie_exited_area", self, "_on_Mini_ellie_exited_area")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	handle_ellie_position()


func handle_ellie_position():
	# Which direction should ellie move, and how fast?
	var point_to_approach = point_for_ellie_to_approach()
	var speed = ELLIE_FLIGHT_SPEED if _ellie_is_inside_float_area else ELLIE_RETURN_SPEED
	var direction = ellie.global_position.direction_to(point_to_approach.global_position)
	var catch_up_accel = ellie.global_position.distance_to(point_to_approach.global_position) / 2
	ellie._velocity = direction * speed * catch_up_accel
	ellie._direction = direction


func point_for_ellie_to_approach() -> Position2D:
	# TODO: Make it so that it takes in other factors into consideration
	return mini.get_node("EllieFloatRange/PointBehindMini")


func _on_Mini_ellie_entered_area() -> void:
	_ellie_is_inside_float_area = true


func _on_Mini_ellie_exited_area() -> void:
	_ellie_is_inside_float_area = false
