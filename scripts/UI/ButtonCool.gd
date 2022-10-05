class_name ButtonCool
extends Button

export var button_sound : AudioStream = load("res://art/audio/sfx/UI/Mouth_08.wav")
export var button_focused_sound : AudioStream = load("res://art/audio/sfx/UI/click_2.wav")
export var animated : bool = true

onready var tween : Tween = Tween.new()
onready var sound : AudioStreamPlayer = AudioStreamPlayer.new()
onready var focused_sound : AudioStreamPlayer = AudioStreamPlayer.new()
onready var mouse_focused : bool = false

func _ready() -> void:
	add_child(tween)
	add_child(sound)
	add_child(focused_sound)
	rect_pivot_offset = rect_size/2
	sound.stream = button_sound
	sound.bus = "Effects"
	focused_sound.stream = button_focused_sound
	focused_sound.bus = "Effects"
	connect("pressed", self, "pressed_effects")
	if(animated):
		connect("mouse_entered", self, "animate_button")
		connect("mouse_exited", self, "stop_animation")
		tween.connect("tween_all_completed", self, "play_animation")
	
func pressed_effects() -> void:
	sound.play(0.0)
	enabled_focus_mode = Control.FOCUS_NONE
	enabled_focus_mode = Control.FOCUS_ALL
	
func animate_button() -> void:
	focused_sound.play(0.0)
	mouse_focused = true
	print(name, " mouse focused: ", mouse_focused)
	play_animation()
	
func play_animation() -> void:
	if(rect_scale == Vector2(1.0, 1.0) and mouse_focused):
		tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(1.1, 1.1), 0.3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	elif(rect_scale != Vector2(1.0, 1.0) and mouse_focused):
		tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(1.0, 1.0), 0.3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
func stop_animation() -> void:
	mouse_focused = false
	tween.interpolate_property(self, "rect_scale", rect_scale, Vector2(1.0, 1.0), 0.3,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
