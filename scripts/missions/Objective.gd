class_name Objective
extends Spatial

signal objective_completed
signal objective_failed

#export var order : int = 0
export var description : String = ""
export var timed : bool = false
export var use_remaining_time : bool = false
export var time : float = 0.0
export var same_music_as_last_objective : bool = true
export var music : AudioStream = null
export var always_visible : bool = false

onready var active : bool = false

func _ready() -> void:
	set_process(false)
	
func _process(delta : float) -> void:
	if(timed and active):
		time -= delta
		update_time_ui()
	if(time <= 0 and timed and active):
		fail_mission()
	
func _setup() -> void:
	active = true
	set_process(true)
	
	if(timed):
		get_parent().get_parent().UI.get_node("missionUI/info/VBoxContainer/timer").visible = true
	
	if(!same_music_as_last_objective):
		var audio_stream_player : AudioStreamPlayer = get_parent().get_parent().get_node("audio_stream_player")
		audio_stream_player.stream = music
		audio_stream_player.play(0.0)
	
func _complete_objective(player : Node = null, area : Node = null) -> void:
	if(active):
		get_parent().last_objective_time = time
		emit_signal("objective_completed")
		
func setup_marker(mark : Spatial, new_texture : Texture) -> Sprite3D:
	var marker : Sprite3D = Sprite3D.new()
	marker.texture = new_texture
	marker.billboard = SpatialMaterial.BILLBOARD_ENABLED
	mark.add_child(marker)
	marker.transform.origin = Vector3(0, 8, 0)
	return marker
		
func update_time_ui() -> void:
	var minutes : int = 0
	var seconds : int = 0
	
	for second in time:
		seconds = second
		if(second >= 60):
			seconds = 0
			minutes += 1
			
	var time_string : String = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	get_parent().get_parent().UI.get_node("missionUI/info/VBoxContainer/timer").text = time_string
		
func fail_mission() -> void:
	emit_signal("objective_failed")
	deactivate()
	
func deactivate() -> void:
	active = false
	set_process(false)
