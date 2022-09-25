class_name ObjectiveChaseCar
extends "res://scripts/missions/Objective.gd"

export var minimum_distance : int = 0
export var throw_items : bool = false
export var throw_items_on_hit : bool = false
export var items_thrown : int = 0
export var items_meshes : Array = []

onready var car_to_follow : Node = $car
onready var car_path : PathAI = $PathAI

func _setup() -> void:
	._setup()
	car_to_follow.get_node("vehicle").set_ai_path(car_path)
	car_to_follow.get_node("vehicle").AI = true
	car_path.connect("path_finished", self, "_complete_objective")
	
	if(minimum_distance > 0):
		get_parent().get_parent().UI.get_node("missionUI/info/VBoxContainer/npcScapeDistance").visible = true
		get_parent().get_parent().UI.get_node("missionUI/info/VBoxContainer/npcScapeDistance").max_value = minimum_distance
		
func _process(delta: float) -> void:
	var player : KinematicBody = get_parent().get_parent().get_parent().get_parent().get_node("player")
	var vehicle : VehicleBody = car_to_follow.get_node("vehicle")
#	var distance : Vector3 = vehicle.global_transform.origin - player.global_transform.origin
	var distance : float = vehicle.global_transform.origin.distance_to(player.global_transform.origin)
	
	if(minimum_distance > 0):
		get_parent().get_parent().UI.get_node("missionUI/info/VBoxContainer/npcScapeDistance").value = lerp(get_parent().get_parent().UI.get_node("missionUI/info/VBoxContainer/npcScapeDistance").value, distance, 0.03)
	
	if(distance >= minimum_distance and minimum_distance > 0):
		emit_signal("objective_failed")
