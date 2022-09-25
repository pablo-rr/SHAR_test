class_name MissionManager
extends Node

export var next_mission_id : int = -1
export var mission_id : int = 0

onready var objective_manager : ObjectiveManager = $ObjectiveManager
onready var mission_npc_giver : RigidBody = $npcRigid
onready var npc_path : PathAI = $predefinedNpcPath
onready var mission_dialog : Spatial = $dialogManager

onready var UI : CanvasLayer = get_parent().get_parent().get_node("ui")

func _ready() -> void:
	var mission : Dictionary = MissionData.get_mission_by_id(mission_id)
	mission_npc_giver.set_ai_path(npc_path)
	mission_npc_giver.connect("mission_assigned", self, "play_dialog")
	mission_dialog.connect("dialog_finished", self, "show_mission_objective")
	objective_manager.connect("mission_completed", self, "load_next_mission")
	UI.get_node("missionUI/objective/title").text = mission.title
	UI.get_node("missionUI/objective/description").text = mission.description
	UI.get_node("missionUI/objective/NinePatchRect/TextureRect").texture = load(mission.objective_image)
	UI.get_node("missionUI/objective/continue").connect("pressed", self, "start_mission")
	
func play_dialog() -> void:
	mission_dialog.start()
	
func show_mission_objective() -> void:
	UI.get_node("missionUI").show_mission_objective()
	
func start_mission() -> void:
#	mission_dialog.end()
	UI.get_node("missionUI").hide_mission_objective()
#	UI.get_node("missionUI").end_cinematic()
	objective_manager.start_mission()
	
func load_next_mission() -> void:
	if(next_mission_id >= 0):
		var mission : Dictionary = MissionData.get_mission_by_id(next_mission_id)
		var mission_instance = load(mission.reference).instance()
		get_parent().add_child(mission_instance)


