class_name MissionManager, "res://art/nodeIcons/treasure-map(1).png"
extends Node

export var next_mission_id : int = -1

onready var mission_id : int = 0
onready var trigger : Node = null
onready var mission_dialog : Spatial = null
onready var objective_manager : ObjectiveManager = $ObjectiveManager

onready var UI : CanvasLayer = get_parent().get_parent().get_parent().get_node("ui")

#func _ready() -> void:
#	setup()
	
func setup() -> void:
	var mission : Dictionary = MissionData.get_mission_by_id(mission_id)
	objective_manager.connect("mission_completed", self, "load_next_mission")
	UI.get_node("missionUI/objective/title").text = mission.title
	UI.get_node("missionUI/objective/description").text = mission.description
	UI.get_node("missionUI/objective/NinePatchRect/TextureRect").texture = load(mission.objective_image)
	UI.get_node("missionUI/objective/continue").connect("pressed", self, "start_mission")
	UI.get_node("missionUI/missionFailed/HBoxContainer/yes").connect("pressed", self, "reset")
	UI.get_node("missionUI/missionFailed/HBoxContainer/no").connect("pressed", self, "cancel")
	
	var audio_stream_player : AudioStreamPlayer = AudioStreamPlayer.new()
	audio_stream_player.bus = "Music"
	audio_stream_player.name = "audio_stream_player"
	add_child(audio_stream_player)
	
#	UI.get_node("missionUI/missionFailed/HBoxContainer/no").connect("pressed", self, "reset")
	
func reset() -> void:
	get_parent().get_parent().get_parent().can_pause = true
	get_tree().paused = false
	trigger.instance_mission(mission_id, true)
	trigger.get_node("npcRigid").assign_mission_skip_dialog()
	get_parent().get_parent().get_parent().get_node("player").global_transform.origin = trigger.dialog_manager.get_node("character1Position").global_transform.origin
	queue_free()
	
func cancel() -> void:
	get_parent().get_parent().get_parent().can_pause = true
	get_tree().paused = false
	trigger.get_node("npcRigid").reset_mission_assignment()
	UI.get_node("missionUI").hide_mission_failed()
	queue_free()
	
func start_mission() -> void:
	get_tree().paused = false
	get_parent().get_parent().get_parent().can_pause = true
	UI.get_node("missionUI").hide_mission_objective()
	objective_manager.start_mission()
	
func load_next_mission() -> void:
	if(next_mission_id >= 0):
		var mission : Dictionary = MissionData.get_mission_by_id(next_mission_id)
		var mission_instance = load(mission.reference).instance()
		get_parent().add_child(mission_instance)
