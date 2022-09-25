class_name PathAI
extends Spatial

signal path_point_changed
signal path_finished

export var circuit : bool = true

var path_points : Array = []
var current_path_point : Area = null
var current_path_point_index : int = 0

func _ready() -> void:
	for child in get_children():
		if(child is Area):
			path_points.append(child)
			child.connect("influence_entered", self, "get_next_path_point")
			
	current_path_point = path_points[0]
			
func get_next_path_point(npc : Node, path_point : Area) -> void:
	if(path_point == npc.current_path_point):
		npc.current_path_point_index += 1
		if(npc.current_path_point_index > path_points.size() -1):
			npc.current_path_point_index = 0
			emit_signal("path_finished")
			
		npc.current_path_point = path_points[npc.current_path_point_index]
