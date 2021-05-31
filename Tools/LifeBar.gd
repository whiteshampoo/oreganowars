
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node2D

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var Fill : Polygon2D = $Fill
onready var Border : Line2D = $Border


#-[VAR]-------------------------------------------------------------------------

var hitpoints : float = 0.0
var hitpoints_max : float = 0.0
var unit_size : Vector2 = Vector2(64, 64)

#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	pass


func _process(_delta : float) -> void:
	pass#update()


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
#	if hitpoints == hitpoints_max: return
#	var r : Rect2 = Rect2()
#	var p : float = (hitpoints / hitpoints_max)
#
#	r.position.x = -unit_size.x / 2 + 16
#	r.position.y = unit_size.y / 2 - 2
#	#r.position = Vector2(-31, 32 - 2)
#	r.size = Vector2((unit_size.x - 2) * p, 4)
#	draw_rect(r, Color(1.0 - p, p, 0.0, 1.0), true)
#
#	r.position.x = -unit_size.x / 2
#	r.position.y = unit_size.y / 2 - 3
#	#r.position = Vector2(-32, 32 - 3)
#	r.size = Vector2(unit_size.x, 5)
#	draw_rect(r, Color.black, false, 1, false)


#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func set_hitpoints(h : float, h_max : float):
	global_position = global_position.round()
	hitpoints = h
	hitpoints_max = h_max
	Fill.visible = not hitpoints == hitpoints_max
	Border.visible = Fill.visible
	var p = hitpoints / hitpoints_max
	Fill.color = Color(1.0 - p, p, 0.0, 1.0)
	var polygon_fill : PoolVector2Array = Fill.polygon
	var points_border : PoolVector2Array = Border.points
	polygon_fill[1].x = unit_size.x * p
	polygon_fill[2].x = polygon_fill[1].x
	points_border[1].x = unit_size.x
	points_border[2].x = points_border[1].x
	Fill.polygon = polygon_fill
	Border.points = points_border
	Fill.position = Vector2(-32, 32) + Vector2(0, unit_size.y - 64)
	Border.position = Fill.position
	
	
	
	

#-[SIGNAL METHODS]--------------------------------------------------------------
