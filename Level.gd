extends Node2D

signal change_room(name_of_room)

onready var respawn_points = $RespawnPoints
onready var out_of_bounds = $OutOfBounds

onready var cam_anchor = $CamAnchor
onready var bubbles_group = $Bubbles

onready var boundaries = $Boundaries

# JUICE
var jump_dust_texture = preload("res://assets/art/juice/JumpDust.png")
var land_dust_texture = preload("res://assets/art/juice/JumpDust.png")

var bubbles


func _ready():
	# Initialize bubbles
	bubbles = bubbles_group.get_children() if bubbles_group != null else null

	# Initialize out of bounds
	if out_of_bounds != null:
		out_of_bounds.connect("body_entered", self, "handle_out_of_bounds")

	var current_room_respawn_points = respawn_points.get_children()

	WorldVars.levels_to_respawn_points[name] = current_room_respawn_points

	for boundary in boundaries.get_children():
		# The only thing that can enter this boundary is mini's room-change-trigger
		boundary.connect("area_entered", self, "change_room_to", [boundary.get_child(0).name])


func change_room_to(_body, name_of_room):
	emit_signal("change_room", name_of_room)


func handle_out_of_bounds(_body: Node2D) -> void:
	print(_body.global_position)
	Events.emit_signal("mini_should_die", _body)


func create_land_dust(_feet_position):
	var land_dust = Sprite.new()
	land_dust.texture = land_dust_texture
	land_dust.vframes = 1
	land_dust.hframes = 4
	land_dust.centered = true
	land_dust.global_position = _feet_position[0]
	add_child(land_dust)
	yield(get_tree().create_timer(WorldVars.DUST_LIFETIME), "timeout")
	land_dust.queue_free()
