
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends CPUParticles2D

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

func killed(pos : Vector2) -> void:
	position = pos
	$Timer.start()
	emitting = false

func check_visibility(fow_buffer : TileMap) -> void:
	if fow_buffer.get_cellv(fow_buffer.world_to_map(position)) == -1:
		visible = true
	else:
		visible = false

#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_Timer_timeout():
	queue_free()
