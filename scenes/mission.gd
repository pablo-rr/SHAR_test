#tool
extends Spatial

var AICar : VehicleBody
var checkpoint : Area
var lastDistance : float
#var currentDistance : float

# Called when the node enters the scene tree for the first time.
func _ready():
	
	checkpoint = $objective1/AICheckpoints/checkpoint1
	AICar = $objective1/AICar
	AICar.set_physics_process(false)
	AICar.get_node("AI/front").enabled = true
	AICar.get_node("AI/left").enabled = true
	AICar.get_node("AI/right").enabled = true
	
func _physics_process(delta):
	AIResetValues()
	AIAcceleration()
	AITurn()
	
func AIAcceleration() -> void:
	if(AICar.get_node("AI/front").get_collider() == null):
		AICar.accelerationActions()
	else:
		AICar.deccelerationActions()
	
func AITurn() -> void:
	if(AICar.get_node("AI/left").get_collider() != null):
		AICar.turnRight()
	elif(AICar.get_node("AI/right").get_collider() != null):
		AICar.turnLeft()
	
func AIResetValues() -> void:
	AICar.resetValues()
	AICar.allInputs()
	AICar.stopCar()
	AICar.fixSpeedCapOverlap()
	AICar.fixCarRotationDegrees()
	AICar.damageOnCollision()
	AICar.engineSound(0.5)

