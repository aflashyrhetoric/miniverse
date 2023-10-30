extends AudioStreamPlayer

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

const BUS_LAYOUT: String = "res://default_bus_layout.tres"
const SONG_IDX = 1
const LOW_PASS_FILTER_IDX = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.connect("mini_entered_bubble", Callable(self, "muffle_audio"))
	Events.connect("mini_exited_bubble", Callable(self, "unmuffle_audio"))
	AudioServer.set_bus_layout(load(BUS_LAYOUT))

	# var low_pass = get_low_pass()
	# AudioServer.add_bus_effect(SONG_IDX, low_pass, LOW_PASS_FILTER_IDX)


func muffle_audio():
	AudioServer.set_bus_effect_enabled(SONG_IDX, LOW_PASS_FILTER_IDX, true)


func unmuffle_audio():
	AudioServer.set_bus_effect_enabled(SONG_IDX, LOW_PASS_FILTER_IDX, false)
