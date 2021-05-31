
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends "res://Buildings/Building.gd"
class_name SmallFactory

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------



#-[VAR]-------------------------------------------------------------------------



#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	pass


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

func Scout_Tier_1(value : int) -> void:
	Build_Unit(value)


func Scout_Tier_2(value : int) -> void:
	Build_Unit(value)


func Tank_Tier_1(value : int) -> void:
	Build_Unit(value)


func Tank_Tier_2(value : int) -> void:
	Build_Unit(value)


func Rocket_Tank_Tier_1(value : int) -> void:
	Build_Unit(value)


func Rocket_Tank_Tier_2(value : int) -> void:
	Build_Unit(value)

#-[SIGNAL METHODS]--------------------------------------------------------------
