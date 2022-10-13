class_name ObjectiveReachArea, "res://art/nodeIcons/path-distance.png"
extends "res://scripts/missions/Objective.gd"

onready var area : Node = null

func _setup() -> void:
	._setup()
	var has_area_node : bool = false
	assert(get_child_count() != 0, "Not a single child found inside ObjectiveReachArea: there should be a 'Area' node.")
	for child in get_children():
		if(child is Area):
			has_area_node = true
			area = child
	assert(has_area_node, "No 'Area' node was found inside the objective")
	
	if(has_area_node):
		area.connect("influence_entered", self, "_complete_objective")
		area.get_node("influence").get_surface_material(0).set_shader_param("albedo", Color(1, 0, 0))
		area.get_node("influence").get_surface_material(0).set_shader_param("emission_color", Color(1, 0, 0))
	
func _complete_objective(player : Node = null, area : Node = null) -> void:
	if(active):
		._complete_objective()
