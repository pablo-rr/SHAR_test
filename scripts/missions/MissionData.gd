extends Node

var mission_data : Dictionary = {
	0 : {
		title = "Paseo desestresante"
		,description = "Sigue los puntos rojos"
		,objective_image = "res://art/UI/missions/mission_test.png"
		,reference = "res://scenes/missions/missions/MissionTest.tscn"
	}
	,
	1 : {
		title = "Algo pasa en el barrio"
		,description = "Persigue al misterioso coche negro hasta su destino, ¡no dejes que se escape!"
		,objective_image = "res://art/UI/missions/mission_test_2.png"
		,reference = "res://scenes/missions/missions/MissionTest2.tscn"
	}
}

func get_mission_by_id(id : int) -> Dictionary:
	for mission in mission_data.keys():
		print(mission)
		if(mission == id):
			return mission_data[mission]
	
	return {}
