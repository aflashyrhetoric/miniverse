extends Node2D

onready var crosshair = $Crosshair
onready var shard_hit_radius = $ShardHitRadius
onready var orb_location = $OrbLocation
onready var ellie_detector = $EllieDetector

onready var bubble_trigger_hit = $BubbleTriggerHit
onready var sound_ellie_entered = $EllieEntered
onready var sound_ellie_exited = $EllieExited

export var DETECTION_RANGE = 80

var _ellie_is_within_range := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	crosshair.visible = false

	# detect when ellie gets nearby
	Events.connect("ellie_entered_action_range", self, "enter_interaction_range")
	Events.connect("ellie_exited_action_range", self, "exit_interaction_range")

	# detect when a shard hits the orb area
	shard_hit_radius.connect("body_entered", self, "handle_shard_hit")

onready var id = get_instance_id()

# func _process(_delta: float) -> void:
	# $Label.text = str(id)


func enter_interaction_range(_action_point) -> void:
	if get_instance_id() == _action_point.get_instance_id():
		_ellie_is_within_range = true
		sound_ellie_entered.play()
		WorldVars.nearest_interaction_point = $OrbLocation
		crosshair.visible = true


func exit_interaction_range(_action_point) -> void:
	if get_instance_id() == _action_point.get_instance_id():
		_ellie_is_within_range = false
		if sound_ellie_entered.playing:
			sound_ellie_entered.stop()

		# if sound_ellie_exited.playing:
		# 	sound_ellie_exited.stop()
		# sound_ellie_exited.play()

		WorldVars.nearest_interaction_point = null
		crosshair.visible = false
		disable_nearby_bubbles()


func get_nearest_bubbles():
	var nearest_bubbles = []
	var bubbles = get_tree().get_nodes_in_group("bubbles")
	for bubble in bubbles:
		if bubble.global_position.distance_to(orb_location.global_position) < DETECTION_RANGE:
			nearest_bubbles.push_back(bubble)

	return nearest_bubbles


func handle_shard_hit(_shard):
	if _ellie_is_within_range:
		enable_nearby_bubbles()
		crosshair.visible = false
		bubble_trigger_hit.play()

		_shard.get_node("Sprite").visible = false
		_shard._velocity = Vector2.ZERO
		_shard.get_node("BulletTrail").emitting = false
		_shard.begin_to_disappear()


func disable_nearby_bubbles():
	for bubble in get_nearest_bubbles():
		bubble._should_disable = true


func enable_nearby_bubbles():
	for bubble in get_nearest_bubbles():
		bubble._should_disable = false
