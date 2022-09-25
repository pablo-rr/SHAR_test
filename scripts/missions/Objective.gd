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

onready var active = false

func _ready() -> void:
	set_process(false)

func _setup() -> void:
	active = true
	set_process(true)
	
	if(timed):
		get_parent().UI.get_node("info/VBoxContainer/timer").visible = true
	
	if(!same_music_as_last_objective):
		var audio_stream_player : AudioStreamPlayer = AudioStreamPlayer.new()
		audio_stream_player.stream = music
		add_child(audio_stream_player)
		audio_stream_player.play()
	
func deactivate() -> void:
	active = false
	set_process(false)
	
func _process(delta : float) -> void:
	if(timed and active):
		time -= delta
	if(time <= 0 and timed and active):
		emit_signal("objective_failed")
		deactivate()
	
func _complete_objective(player : Node = null, area : Node = null) -> void:
	if(active):
		print("Objective completed")
		emit_signal("objective_completed")
