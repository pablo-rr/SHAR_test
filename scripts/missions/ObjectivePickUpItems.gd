class_name ObjectivePickUpItems, "res://art/nodeIcons/ecology.png"
extends "res://scripts/missions/Objective.gd"

onready var total_items : int = 0
onready var items_picked : int = 0

func _setup() -> void:
	._setup()
	for child in get_children():
		if(child is Area):
			total_items += 1
			child.connect("area_entered", self, "pick_item", [child])
			print("ok")
			
func pick_item(item : Area) -> void:
	items_picked += 1
	item.queue_free()
	if(items_picked >= total_items):
		_complete_objective()
		
	print(items_picked, " ", total_items)
		
	
func _complete_objective(player : Node = null, area : Node = null) -> void:
	if(active):
		._complete_objective()
