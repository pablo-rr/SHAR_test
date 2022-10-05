class_name ObjectiveGetInCar
extends "res://scripts/missions/Objective.gd"

onready var player_car_marker : Sprite3D = null

func _setup() -> void:
	._setup()
	player_car_marker = setup_marker(get_parent().get_parent().get_parent().get_parent().get_parent().player_car.get_node("vehicle"), load("res://art/sprites/markerGetInCar.png"))
	get_parent().get_parent().get_parent().get_parent().get_parent().get_node("player").connect("entered_car", self, "_complete_objective")
	
func _complete_objective(player : Node = null, area : Node = null) -> void:
	if(active):
		player_car_marker.queue_free()
		._complete_objective()
