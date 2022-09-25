extends Area

func _on_rampBooster_body_entered(body: Node) -> void:
	print("ent")
	if(body.collision_layer == CollisionEnums.COLLISION_PLAYER_CAR or body.collision_layer == CollisionEnums.COLLISION_NPC_CAR):
		body.engine_force *= 3
		print("XD")
