
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Area2D

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------

signal unit_selected(units)
signal building_selected(building)
signal deselect

#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var Box : RectangleShape2D = $CollisionShape2D.shape

#-[VAR]-------------------------------------------------------------------------

var active : bool = false
var box_rect : Rect2 = Rect2()
var selected_units : Array = Array()
var selected_building : Node2D = null

#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	pass


func _process(_delta : float) -> void:
	if active:
		position = box_rect.position + box_rect.size / 2.0
	else:
		position = get_global_mouse_position()
	Box.extents = box_rect.size / 2.0
	update()


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	if Global.placing_building: return
	if event is InputEventMouseButton:
		if Global.get_global_mouse_position().x > get_viewport_rect().end.x: return
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				active = true
				box_rect.position = get_global_mouse_position()
				box_rect.size = Vector2.ZERO
			else:
				if not active: return
				active = false
				box_rect.position = Vector2.ZERO
				box_rect.size = Vector2.ONE
				for unit in Global.selected_units:
					if is_instance_valid(unit):
						unit.deselect()
				if is_instance_valid(Global.selected_building):
					Global.selected_building.deselect()
				if selected_units:
					for units in selected_units:
						units.select()
						units.set_hover(false)
					Global.selected_units = selected_units.duplicate()
					selected_units.clear()
					Global.selected_building = null
					emit_signal("unit_selected")
				elif selected_building:
					selected_building.select()
					Global.selected_building = selected_building
					Global.selected_units.clear()
					emit_signal("building_selected")
				else:
					Global.selected_units = []
					emit_signal("deselect")
		return
		
	if event is InputEventMouseMotion:
		if not active:
			return
		box_rect.end = get_global_mouse_position()


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass


func _draw() -> void:
	var rect : Rect2 = box_rect
	rect.position -= global_position
	if active:
		draw_rect(rect, Color.white, false, 2.0, true)

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------



#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_SelectionBox_area_entered(area : Area2D):
	var parent = area.get_parent()
	if not area.name == "SelectionArea": return
	if not parent.is_in_group("Unit") and not parent.is_in_group("Building"): return
	if not parent.faction == Global.player_faction: return
	if parent.is_in_group("Unit"):
		if parent in selected_units: return
		selected_units.append(parent)
		parent.set_hover(true)
	else:
		selected_building = parent



func _on_SelectionBox_area_exited(area : Area2D):
	var parent = area.get_parent()
	if not area.name == "SelectionArea": return
	if not parent.is_in_group("Unit") and not parent.is_in_group("Building"): return
	if parent.is_in_group("Unit"):
		if not parent in selected_units: return
		selected_units.erase(parent)
		parent.set_hover(false)
	else:
		if selected_building == parent:
			selected_building = null
