extends Node2D

@onready var display_width = ProjectSettings.get("display/window/size/viewport_width")
@onready var display_height = ProjectSettings.get("display/window/size/viewport_height")

@onready var first = $First
@onready var cam = $Camera3D
@onready var player = $Player

@onready var song = $Song
@onready var ambience = $Rain

# TODO: Optimize later if necessary, make dynamic if necessary
const WINDOW_WIDTH = 320.0
const WINDOW_HEIGHT = 180.0

const CAMERA_TRACK_PREFIX_TALL = "Tall"
const CAMERA_TRACK_PREFIX_WIDE = "Wide"

enum CAMERA_TRACK_MODES { STATIC, X, Y }

var _camera_track_mode = CAMERA_TRACK_MODES.STATIC

var _is_mid_transition: bool = false


func _ready():
	# Set the initial camera position
	cam.global_position = first.cam_anchor.position

	# Handle events
	Events.connect("mini_died", Callable(self, "handle_death"))

	# For every room, initialize scene-change orchestration process
	var rooms = get_tree().get_nodes_in_group("rooms")
	for room in rooms:
		room.connect("change_room", Callable(self, "_move_camera"))


func _process(_delta: float) -> void:
	if not _is_mid_transition:
		if _camera_track_mode == CAMERA_TRACK_MODES.X:
			cam.position.x = lerp(cam.position.x, player.mini.global_position.x, 0.1)
		if _camera_track_mode == CAMERA_TRACK_MODES.Y:
			var room_top = WorldVars.current_room.get_node("RoomTop").global_position.y
			var room_bottom = WorldVars.current_room.get_node("RoomBottom").global_position.y
			room_top += WINDOW_HEIGHT / 2
			room_bottom -= WINDOW_HEIGHT / 2
			var would_be_pos_y: float = lerp(cam.position.y, player.mini.global_position.y, 0.1)
			if would_be_pos_y > room_top and would_be_pos_y < room_bottom:
				cam.position.y = would_be_pos_y
		if _camera_track_mode == CAMERA_TRACK_MODES.STATIC:
			# Do nothing after the CamAnchor has been focused and centered!
			pass


func handle_death(_body):
	var respawn_pt = get_nearest_respawn_point(_body.global_position)
	player.mini.global_position = respawn_pt.global_position
	pass


func get_nearest_respawn_point(_pos: Vector2) -> Marker2D:
	var current_room_respawn_points = WorldVars.levels_to_respawn_points[WorldVars.current_room_name]
	var closest = null
	var closest_distance = 99999.0

	for respawn_point in current_room_respawn_points:
		var d = _pos.distance_to(respawn_point.global_position)
		if closest == null or d < closest_distance:
			closest = respawn_point
			closest_distance = d

	return closest


func _move_camera(name_of_room: String):
	_is_mid_transition = true
	# reset
	_camera_track_mode = CAMERA_TRACK_MODES.STATIC

	if WorldVars.current_room_name == name_of_room:
		return

	if Util.str_includes(name_of_room, CAMERA_TRACK_PREFIX_TALL):
		_camera_track_mode = CAMERA_TRACK_MODES.Y

	if Util.str_includes(name_of_room, CAMERA_TRACK_PREFIX_WIDE):
		_camera_track_mode = CAMERA_TRACK_MODES.X

	print("entered room, ", name_of_room, ". active cam is set to: ", _camera_track_mode)

	# If we're here, we're trying to transition rooms!
	player.mini.pause_movement()
	var new_room = get_node(name_of_room)
	var new_pos: Vector2 = new_room.cam_anchor.global_position
	var tween = $CamTween
	tween.interpolate_property(
		cam, "position", cam.global_position, new_pos, 0.65, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	if tween.is_connected("tween_completed", Callable(self, "update_room_name")):
		tween.disconnect("tween_completed", Callable(self, "update_room_name"))
	tween.connect("tween_completed", Callable(self, "update_room_name").bind(new_room))
	tween.start()


func update_room_name(_obj, _key, new_room: Node2D):
	print("updated to ", new_room.name)
	player.mini.unpause_movement()
	WorldVars.current_room_name = new_room.name
	WorldVars.current_room = new_room
	_is_mid_transition = false
