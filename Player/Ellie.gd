class_name Ellie
extends Actor

# Declare member variables here. Examples:
# var a: int = 2
# var b: S	tring = "text"

var is_mini = false

const Shard = preload("res://World/Shard.tscn")

onready var sprite = $Sprite
onready var shard_shooter = $ShardShooter
onready var shard_spawn_pt = $ShardSpawnPoint
onready var ellie_fire_action_shard = $EllieFireActionShard

var _direction = Vector2.ZERO

var _nearest_activation_point_is_activated = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.connect("ellie_exited_action_range", self, "reset_action_range_vars")
	Events.connect("mini_died", self, "handle_mini_death")


func _process(_body) -> void:
	if (
		Input.is_action_just_pressed("ellie_interact")
		and WorldVars.nearest_interaction_point != null
		and not _nearest_activation_point_is_activated
	):
		# So that Ellie can't fire a million missiles
		_nearest_activation_point_is_activated = true

		var direction = shard_spawn_pt.global_position.direction_to(
			WorldVars.nearest_interaction_point.global_position
		)
		add_child(
			Factory.shard(
				shard_spawn_pt.global_position,
				WorldVars.nearest_interaction_point.global_position,
				direction
			)
		)
		ellie_fire_action_shard.play()


func handle_mini_death(_unused):
	reset_action_range_vars(_unused)


func reset_action_range_vars(_action_point):
	print("reset")
	_nearest_activation_point_is_activated = false


func _physics_process(delta):
	global_position = global_position + (_velocity * delta)


func handle_death() -> void:
	pass
