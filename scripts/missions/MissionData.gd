extends Node

var mission_data : Dictionary = {
	0 : {
		title = tr("msnttl_missionTest1")
		,description = tr("msndsc_missionTest1")
		,objective_image = "res://art/UI/missions/mission_test.png"
		,trigger = preload("res://scenes/missions/triggers/MissionTriggerTest1.tscn")
		,reference = preload("res://scenes/missions/missions/MissionTest1.tscn")
	}
	,
}

func get_mission_by_id(id : int) -> Dictionary:
	for mission in mission_data.keys():
		if(mission == id):
			return mission_data[mission]
	
	return {}
