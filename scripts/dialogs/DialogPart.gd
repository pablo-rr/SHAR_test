class_name DialogPart
extends Node

signal dialog_part_completed

const CHARACTER_TALKING_1 : int = 0
const CHARACTER_TALKING_2 : int = 1

export(int, "Character 1", "Character 2") var character_talking : int
export var dialog_audio : AudioStream = null
export var dialog_text : String = ""
export var intro_delay : float = 0
export var next_dialog_delay : float = 0.1
