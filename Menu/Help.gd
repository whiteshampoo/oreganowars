
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Control

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------



#-[VAR]-------------------------------------------------------------------------



#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	Log.line("Submenu ready", self, Log.LEVEL.INFO)
	$MapGenerator.generate_map(64, 36, 0, randi())


func _process(_delta : float) -> void:
	pass


func _physics_process(_delta : float) -> void:
	pass


func _input(_event : InputEvent) -> void:
	pass


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass


func _draw() -> void:
	pass

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------



#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_Back_pressed():
	Log.line("Back pressed", self, Log.LEVEL.INFO)
	get_tree().change_scene("res://Menu/Main.tscn")


func _on_Text_meta_clicked(meta : String):
	meta = meta.strip_edges()
	Log.line("Meta clicked", self, Log.LEVEL.INFO, [meta])
	OS.shell_open(meta)
