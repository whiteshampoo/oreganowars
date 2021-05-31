
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends "res://Buildings/Building.gd"
class_name HeadQuarter

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

func Wall(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Small_Factory(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Big_Factory(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Oregano_Refinery(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func MG_Tower_Tier_1(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func MG_Tower_Tier_2(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Cannon_Tower_Tier_1(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Cannon_Tower_Tier_2(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Rocket_Tower_Tier_1(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)


func Rocket_Tower_Tier_2(value : int) -> void:
# warning-ignore:return_value_discarded
	Build_Building(value)

#-[SIGNAL METHODS]--------------------------------------------------------------
