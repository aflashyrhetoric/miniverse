extends Node2D

signal change_room(name_of_room)

# onready var display_width = ProjectSettings.get("display/window/size/width")
# onready var display_height = ProjectSettings.get("display/window/size/height")

onready var respawn_point = $RespawnPoint
onready var out_of_bounds = $OutOfBounds

onready var cam_anchor = $CamAnchor
onready var bubbles_group = $Bubbles

onready var boundaries = $Boundaries

var bubbles

var _should_respawn = false
var _player


func _ready():
	# Initialize bubbles
	bubbles = bubbles_group.get_children() if bubbles_group != null else null

	# Initialize out of bounds
	out_of_bounds.connect("body_entered", self, "mini_fell_out_of_bounds")
	for boundary in boundaries.get_children():
		print("processing boundary", boundary.name)
		boundary.connect("area_entered", self, "change_room_to", [boundary.get_child(0).name])


func initialize_level(player):
	_player = player
	# Connect the signals emitted by the bubble to the handler in Mini.gd
	for hp in bubbles:
		hp.connect("mini_entered_bubble", player, "mini_entered_bubble")
		hp.connect("mini_exited_bubble", player, "mini_exited_bubble")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if _should_respawn:
		for child in _player.get_children():
			child.global_position = respawn_point.global_position
			child.died()
			_should_respawn = false

func change_room_to(_body, name_of_room):
	print("detected")
	emit_signal("change_room", name_of_room)

func mini_fell_out_of_bounds(_body: Node) -> void:
	_should_respawn = true
