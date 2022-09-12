class_name Player
extends Node2D

## ELLIE CONSTANTS
const ELLIE_FLIGHT_SPEED = Vector2(50, 30)
const ELLIE_RETURN_SPEED = Vector2(10, 10)

# The BBs! :D
onready var mini = $Mini
onready var ellie = $Ellie

# Instance variables
var _ellie_is_inside_float_area = true

# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	var hook_points = get_tree().get_nodes_in_group("hook_points")
# 	for hook_point in hook_points:
# 		print(hook_point)
# 		hook_point.connect("body_entered", self, "_on_HookPoint_mini_entered")
# 		hook_point.connect("body_exited", self, "_on_HookPoint_mini_exited")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	handle_ellie_position()
	hook_if_possible()
	pass


func hook_if_possible():
	pass


func handle_ellie_position():
	var is_attacking = false  # TODO: Make this dynamically update when ellie is actually attacking
	if !is_attacking:
		# if mini is on the floor, adjust y movement speed toward position2d to mitigate wobble
		if !mini.is_on_floor():
			pass

		# If ellie is out of the box, move toward the point
		compute_direction_and_distance_accel()
	pass


# Which direction should ellie move, and how fast?
func compute_direction_and_distance_accel():
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


func mini_entered_hookzone():
	mini.grant_extra_jump()


func mini_exited_hookzone():
	pass
