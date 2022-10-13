class_name MissionTrigger, "res://art/nodeIcons/movement-sensor.png"
extends Node

export var mission_id : int = 0

onready var npc : RigidBody = $npcRigid
onready var npc_path : PathAI = $predefinedNpcPath
onready var dialog_manager : Spatial = $dialogManager
onready var mission : PackedScene
onready var UI : CanvasLayer = get_parent().get_parent().get_parent().get_node("ui")

func _ready() -> void:
	npc.set_ai_path(npc_path)
	npc.connect("mission_assigned", self, "instance_mission", [mission_id, false])
#	npc.connect("mission_assigned", self, "instance_mission", [mission_id, true])

func instance_mission(id : int, skip_dialog : bool) -> void:
	mission = MissionData.get_mission_by_id(id).reference
	var mission_instance : MissionManager = mission.instance()
	get_parent().get_parent().get_node("current").add_child(mission_instance)
	mission_instance.mission_id = mission_id
	mission_instance.trigger = self
	mission_instance.mission_dialog = $dialogManager
	mission_instance.setup()
	dialog_manager.connect("dialog_finished", self, "show_mission_objective")
	UI.get_node("missionUI/cinematicBars/bottom/skip").connect("pressed", self, "skip_dialog")
#	UI.get_node("missionUI/cinematicBars/bottom/cancel").connect("pressed", self, "skip_dialog")
	
	if(!skip_dialog):
		dialog_manager.start()
	else:
		show_mission_objective()
		
func show_mission_objective() -> void:
	UI.get_node("missionUI").show_mission_objective()
	get_tree().paused = true
	
func skip_dialog() -> void:
	dialog_manager.current_dialog_audio.stop()
	dialog_manager.end()
