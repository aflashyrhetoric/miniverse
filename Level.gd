extends Node2D

signal change_room(name_of_room)

# onready var display_width = ProjectSettings.get("display/window/size/width")
# onready var display_height = ProjectSettings.get("display/window/size/height")

onready var respawn_point = $RespawnPoint
onready var out_of_bounds = $OutOfBounds

onready var cam_anchor = $CamAnchor
onready var bubbles_group = $Bubbles

onready var boundaries = $Boundaries

# JUICE
var jump_dust_texture = preload("res://assets/art/juice/JumpDust.png")
var land_dust_texture = preload("res://assets/art/juice/JumpDust.png")

var bubbles

var _should_respawn = false
var _player


func _ready():
	# Initialize bubbles
	bubbles = bubbles_group.get_children() if bubbles_group != null else null

	# Initialize out of bounds
	out_of_bounds.connect("body_entered", self, "mini_died")
	Events.connect("mini_died", self, "handle_death")
	# Events.connect("mini_landed", self, "create_land_dust")

	for boundary in boundaries.get_children():
		# The only thing that can enter this boundary is mini's room-change-trigger
		boundary.connect("area_entered", self, "change_room_to", [boundary.get_child(0).name])


func initialize_level(player):
	_player = player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if _should_respawn:
		_should_respawn = false
		for child in _player.get_children():
			if child.is_mini:
				child.global_position = respawn_point.global_position
				child.handle_death()

func change_room_to(_body, name_of_room):
	emit_signal("change_room", name_of_room)

func mini_died(_body: Node) -> void:
	Events.emit_signal("mini_died")

func handle_death():
	if name == WorldVars._active_room:
		_should_respawn = true

func create_land_dust(_feet_position: Vector2):
	var land_dust = Sprite.new()
	land_dust.texture = land_dust_texture
	land_dust.vframes = 1
	land_dust.hframes = 4
	land_dust.centered = true
	land_dust.global_position = _feet_position
	add_child(land_dust)
	yield(get_tree().create_timer(WorldVars.DUST_LIFETIME), "timeout")
	land_dust.queue_free()
