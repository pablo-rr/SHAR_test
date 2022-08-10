extends Node

var associated_wheel : VehicleWheel

func set_associated_wheel(wheel : VehicleWheel) -> void:
	associated_wheel = wheel
	
func get_associated_wheel() -> VehicleWheel:
	return associated_wheel


