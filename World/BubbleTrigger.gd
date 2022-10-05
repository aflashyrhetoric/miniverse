extends Node2D

onready var crosshair = $Crosshair

const DETECTION_RANGE = 80


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	crosshair.visible = false
	Events.connect("ellie_entered_action_range", self, "add_crosshair")
	Events.connect("ellie_exited_action_range", self, "remove_crosshair")
	# print(bubble_activation_range.get_overlapping_areas())


func get_nearest_bubbles():
	var nearest_bubbles = []
	var bubbles = get_tree().get_nodes_in_group("bubbles")
	for bubble in bubbles:
		if bubble.global_position.distance_to(global_position) < DETECTION_RANGE:
			nearest_bubbles.push_back(bubble)

	return nearest_bubbles


func add_crosshair(_body) -> void:
	crosshair.visible = true


func remove_crosshair(_body) -> void:
	crosshair.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
