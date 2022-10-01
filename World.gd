extends Node2D

onready var display_width = ProjectSettings.get("display/window/size/width")
onready var display_height = ProjectSettings.get("display/window/size/height")

onready var first = $First
onready var cam = $Camera
onready var player = $Player

onready var song = $Song
onready var ambience = $Rain

const CAMERA_TRACK_PREFIX_TALL = "Tall"
const CAMERA_TRACK_PREFIX_WIDE = "Wide"

enum CAMERA_TRACK_MODES { STATIC, X, Y }

var _camera_track_mode = CAMERA_TRACK_MODES.STATIC


func _ready():
	cam.global_position = first.cam_anchor.position
	Events.connect("mini_died", self, "handle_death")
	var rooms = get_tree().get_nodes_in_group("rooms")
	for room in rooms:
		room.connect("change_room", self, "_move_camera")


func _process(_delta: float) -> void:
	if _camera_track_mode == CAMERA_TRACK_MODES.X:
		cam.position.x = lerp(cam.position.x, player.mini.global_position.x, 0.1)
	if _camera_track_mode == CAMERA_TRACK_MODES.Y:
		cam.position.y = lerp(cam.position.y, player.mini.global_position.y, 0.1)
	if _camera_track_mode == CAMERA_TRACK_MODES.STATIC:
		# Do nothing after the CamAnchor has been focused and centered!
		pass


func handle_death(_body):
	var respawn_pt = get_nearest_respawn_point(_body.global_position)
	player.mini.global_position = respawn_pt.global_position
	pass


func get_nearest_respawn_point(_pos: Vector2) -> Position2D:
	var current_room_respawn_points = WorldVars.levels_to_respawn_points[WorldVars.current_room]
	var closest = null
	var closest_distance = 99999.0

	for respawn_point in current_room_respawn_points:
		var d = _pos.distance_to(respawn_point.global_position)
		if closest == null or d < closest_distance:
			closest = respawn_point
			closest_distance = d

	return closest


func _move_camera(name_of_room: String):
	# reset
	_camera_track_mode = CAMERA_TRACK_MODES.STATIC

	if WorldVars.current_room == name_of_room:
		return true

	if Util.str_includes(name_of_room, CAMERA_TRACK_PREFIX_TALL):
		_camera_track_mode = CAMERA_TRACK_MODES.Y

	if Util.str_includes(name_of_room, CAMERA_TRACK_PREFIX_WIDE):
		_camera_track_mode = CAMERA_TRACK_MODES.X

	print("entered room, ", name_of_room, ". active cam is set to: ", _camera_track_mode)

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
	WorldVars.current_room = name_of_room
