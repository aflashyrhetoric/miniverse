extends Node

var current_room_name: String = "First"
var current_room: Node2D = null

var levels_to_respawn_points = {}

var nearest_interaction_point = null

var DUST_LIFETIME: float = 0.3
