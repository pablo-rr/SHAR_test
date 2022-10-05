extends Camera

#export var nodeFollowingPath : NodePath
#export var nodeLookingAtPath : NodePath
export var followSpeed : float = 0.3
export var followOffset : Vector3

var nodeFollowing : Node
var nodeLookingAt : Node
onready var nodeLookingAtPath : NodePath = @"../cars/car/vehicle"

func _ready() -> void:
	setupNodes()
	setupNodeLookingAtPath()
	
func _physics_process(delta : float) -> void:
	look_at(nodeLookingAt.global_transform.origin, Vector3(0, 1, 0))
	transform.origin = lerp(global_transform.origin, nodeFollowing.global_transform.origin, followSpeed)

func setupNodes() -> void:
	nodeLookingAt = get_node(nodeLookingAtPath)
	if(nodeLookingAt.get_node("camPos")):
		nodeFollowing = nodeLookingAt.get_node("camPos")
	else:
		nodeFollowing = nodeLookingAt
		
func setupNodeLookingAtPath() -> void:
	pass
#	var path : String = "../playerCar/"
#	var car : String = "car" in path.get_children()[0].name
#	nodeLookingAtPath = @"../playerCar/"
