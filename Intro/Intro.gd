
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var IntroPlayer : AnimationPlayer = $IntroPlayer

#-[VAR]-------------------------------------------------------------------------

var original_viewport : Vector2 = Vector2.ZERO

#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	Log.move_to_bottom()
	Log.line("Intro ready", self, Log.LEVEL.INFO)
	IntroPlayer.play("Intro")
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(960, 512), 1)


func _process(_delta : float) -> void:
	pass


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_cancel"):
			goto_menu()
		


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func goto_menu() -> void:
	Log.line("Intro finished", self, Log.LEVEL.INFO)
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Menu/Main.tscn")

#-[SIGNAL METHODS]--------------------------------------------------------------

