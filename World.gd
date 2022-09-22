extends Node2D

onready var display_width = ProjectSettings.get("display/window/size/width")
onready var display_height = ProjectSettings.get("display/window/size/height")

# LEVELS
onready var first = $First
onready var cam = $Camera
# onready var respawn_point = $RespawnPoint
# onready var out_of_bounds = $OutOfBounds
onready var player = $Player
# onready var mini = player.get_node("Mini")

var _should_respawn = false


func _ready():
	cam.global_position = first.cam_anchor.position
	var rooms = get_tree().get_nodes_in_group("rooms")
	for room in rooms:
		room.initialize_level(player)
		room.connect("change_room", self, "_move_camera")
	# get_tree().call_group("rooms", "initialize_level", player)


func _move_camera(name_of_room: String):
	if WorldVars._active_room == name_of_room:
		return true

	# If we're here, we're trying to transition rooms!
	player.mini.pause_movement()
	print("trying to get name of room: ", name_of_room)
	var new_pos: Vector2 = get_node(name_of_room).cam_anchor.global_position
	print("position of room: ", new_pos)
	var tween = $CamTween
	tween.interpolate_property(
		cam, "position", cam.global_position, new_pos, 0.65, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween.disconnect("tween_completed", self, "update_room_name")
	tween.connect("tween_completed", self, "update_room_name", [name_of_room])
	tween.start()


func update_room_name(_obj, _key, name_of_room: String):
	print("updated to ", name_of_room)
	player.mini.unpause_movement()
	WorldVars._active_room = name_of_room
