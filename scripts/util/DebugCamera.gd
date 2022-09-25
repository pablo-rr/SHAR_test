class_name DebugCamera
extends Camera

export var active : bool = false

func _ready() -> void:
	projection = Camera.PROJECTION_ORTHOGONAL

func _process(delta: float) -> void:
	if(active):
		current = true
