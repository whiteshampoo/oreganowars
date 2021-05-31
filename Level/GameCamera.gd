
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Camera2D

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var CamZoom : Tween = $CamZoom
onready var CamMove : Tween = $CamMove

#-[VAR]-------------------------------------------------------------------------

var target_zoom : Vector2 = Vector2.ONE
var min_zoom : float = 1.0
var max_zoom : float = 2.0
var move_cam : bool = false

var map_size : Vector2 = Vector2.ZERO setget set_map_size
var dimension : Rect2 = Rect2()

#-[SETGET METHODS]--------------------------------------------------------------

func set_map_size(ms : Vector2):
	map_size = ms
	map_size -= Vector2.ONE * 32
	if map_size.x > 0 and map_size.y > 0:
		recalc_and_interpolate()
		limit_right = int(map_size.x * 64)
		limit_bottom = int(map_size.y * 64)

#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	limit_left = 64
	limit_top = 64
	zoom = target_zoom
	recalc_and_interpolate()
	var __ = get_viewport().connect("size_changed", self, "recalc_and_interpolate", [true])


func _process(delta : float) -> void:
	var movement : Vector2 = Vector2.ZERO
	movement.x = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	movement.y = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	movement = movement.normalized() * delta * 750.0 * (Input.get_action_strength("ui_fast") + 1.0)
	if movement:
		move_camera(movement)
		
	if Input.is_action_pressed("zoom_in"):
		zoom_camera(false)
	elif Input.is_action_pressed("zoom_out"):
		zoom_camera(true)


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_WHEEL_UP, BUTTON_WHEEL_DOWN:
				if Global.get_global_mouse_position().x > get_viewport_rect().end.x: return
				if event.pressed:
					zoom_camera(event.button_index == BUTTON_WHEEL_DOWN)
	
					
			BUTTON_MIDDLE:
				move_cam = event.pressed

					
	elif event is InputEventMouseMotion:
		if not move_cam or CamMove.is_active():
			return
		move_camera(event.relative)


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass


func _draw() -> void:
	pass

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func zoom_camera(in_out : bool) -> void:
	var z : float = 0.2 
	if in_out:
		z *= -1
	target_zoom.x -= z
	target_zoom.y -= z
	recalc_and_interpolate()

func test_move_camera(new_pos : Vector2) -> Vector2:
	new_pos.x = clamp(new_pos.x, dimension.position.x, dimension.end.x)
	new_pos.y = clamp(new_pos.y, dimension.position.y, dimension.end.y)
	return new_pos


func move_camera(relative : Vector2 = Vector2.ZERO) -> void:
	position = test_move_camera(position - relative)


func interpolate_zoom_and_position(viewport_change : bool = false) -> void:
	var __
	if zoom != target_zoom:
		__ = CamZoom.remove_all()
		__ = CamZoom.interpolate_property(self, "zoom", null, 
								target_zoom, 0.0 if viewport_change else 0.2, 
								Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		__ = CamZoom.start()
	if test_move_camera(position) != position:
		__ = CamMove.remove_all()
		__ = CamMove.interpolate_property(self, "position", null,
								test_move_camera(position), 0.0 if viewport_change else 0.2,
								Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		__ = CamMove.start()


func calc_dimensions(viewport_change : bool = false) -> void:
	var vrect : Rect2 = get_viewport_rect()
	if map_size.x == 0 or map_size.y == 0 or vrect.size.x == 0 or vrect.size.y == 0:
		return
	
	max_zoom = min(2.0, map_size.x / vrect.size.x)
	max_zoom = min(max_zoom, map_size.y / vrect.size.y)
	
	min_zoom = min(1.0, map_size.x / vrect.size.x)
	min_zoom = min(min_zoom, map_size.y / vrect.size.y)
	
	var old_target_zoom : Vector2 = target_zoom	
	target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
	target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)
	if old_target_zoom != target_zoom and viewport_change:
		zoom = target_zoom
	
	dimension.position = vrect.size * target_zoom.x * 0.5
	dimension.end = map_size - vrect.size * target_zoom.x * 0.5



func recalc_and_interpolate(viewport_change : bool = false) -> void:
	calc_dimensions(viewport_change)
	interpolate_zoom_and_position()

#-[SIGNAL METHODS]--------------------------------------------------------------
