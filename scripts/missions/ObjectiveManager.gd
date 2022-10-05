class_name ObjectiveManager
extends Spatial

signal mission_completed
signal mission_inited
signal mission_started

onready var objectives : Array = []
onready var current_objective_index : int = 0
onready var current_objective : Node = null
onready var last_objective_time : float = 0.0

func start_mission() -> void:
	get_next_objective()
	
func _ready() -> void:
	for child in get_children():
		objectives.append(child)
		if(!child.always_visible):
			child.visible = false

	connect("mission_completed", self, "complete_mission")
	
func show_next_objective() -> void:
	if(current_objective_index < objectives.size() -1):
		objectives[current_objective_index +1].visible = true
	
func get_next_objective() -> void:
	if(current_objective == null):
		current_objective = objectives[0]
		current_objective._setup()
		current_objective.connect("objective_failed", self, "fail_mission")
		current_objective.connect("objective_completed", self, "get_next_objective")
	elif(current_objective == objectives[objectives.size() -1]):
		current_objective.deactivate()
		current_objective.visible = false
		emit_signal("mission_completed")
	else:
		current_objective.visible = false
		current_objective.deactivate()
		current_objective.disconnect("objective_failed", self, "fail_mission")
		current_objective.disconnect("objective_completed", self, "get_next_objective")
		current_objective_index += 1
		current_objective = objectives[current_objective_index]
		current_objective._setup()
		current_objective.connect("objective_failed", self, "fail_mission")
		current_objective.connect("objective_completed", self, "get_next_objective")
		
	if(current_objective.use_remaining_time):
		current_objective.time = last_objective_time
	current_objective.visible = true
	show_next_objective()
		
func fail_mission() -> void:
	get_parent().get_parent().get_parent().get_parent().can_pause = false
	get_tree().paused = true
	get_parent().UI.get_node("missionUI").show_mission_failed()
	
func complete_mission() -> void:
	get_parent().UI.get_node("missionUI").show_mission_completed()
	get_parent().queue_free()
