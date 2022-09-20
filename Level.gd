extends Node2D

onready var display_width = ProjectSettings.get("display/window/size/width")
onready var display_height = ProjectSettings.get("display/window/size/height")

onready var viewport = $Camera
onready var respawn_point = $RespawnPoint
onready var out_of_bounds = $OutOfBounds
onready var player = $Player
onready var hook_point_group = $HookPoints
onready var hook_points = hook_point_group.get_children()

var _should_respawn = false

func _ready():
	initialize_level()

func initialize_level():
	for hp in hook_points:
		hp.connect("mini_entered_hookzone", player, "mini_entered_hookzone")
		hp.connect("mini_exited_hookzone", player, "mini_exited_hookzone")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if _should_respawn:
		for child in player.get_children():
			child.global_position = respawn_point.global_position
			child.died()
			_should_respawn = false


func _on_OutOfBounds_body_entered(_body: Node) -> void:
	_should_respawn = true
