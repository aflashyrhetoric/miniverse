extends Node2D

onready var display_width = ProjectSettings.get("display/window/size/width")
onready var display_height = ProjectSettings.get("display/window/size/height")

onready var first = $First
onready var cam = $Camera
onready var player = $Player

onready var song = $Song
onready var ambience = $Rain

var camera_track_prefixes = ["Tall", "Wide"]

var _should_track_camera_actively = false


func _ready():
	cam.global_position = first.cam_anchor.position
	var rooms = get_tree().get_nodes_in_group("rooms")
	for room in rooms:
		room.initialize_level(player)
		room.connect("change_room", self, "_move_camera")


func _process(_delta: float) -> void:
	if _should_track_camera_actively:
		cam.position.y = lerp(cam.position.y, player.mini.global_position.y, 0.1)


func _move_camera(name_of_room: String):
	# reset
	_should_track_camera_actively = false

	if WorldVars._active_room == name_of_room:
		return true

	for prefix in camera_track_prefixes:
		if Util.str_includes(name_of_room, prefix):
			_should_track_camera_actively = true

	print("entered room, ", name_of_room, ". active cam is set to: ", _should_track_camera_actively)

	# If we're here, we're trying to transition rooms!
	player.mini.pause_movement()
	var new_pos: Vector2 = get_node(name_of_room).cam_anchor.global_position
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
