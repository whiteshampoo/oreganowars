
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node2D
class_name Barrel

#-[CONSTANTS]-------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------

#signal enemy_spotted(enemy)

#-[EXPORT]----------------------------------------------------------------------

export var reload_time : float = 1.0
export var turn_speed : float = 100.0
export var range_radius : float = 5.0
export var bullet_scene : PackedScene = null

#-[ONREADY]---------------------------------------------------------------------

onready var Reload : Timer = $Reload
onready var BarrelEnds : Node2D = $BarrelEnds
onready var RangeCircle : CollisionShape2D = $Range/Circle

#-[VAR]-------------------------------------------------------------------------

var can_shoot : bool = true
var enemies_in_range : Array = Array()
var target : Node2D = null
var desired_target : Node2D = null setget set_desired_target
var barrel = 0

#-[SETGET METHODS]--------------------------------------------------------------

func set_desired_target(t : Node2D) -> void:
	if is_instance_valid(t):
		#print("set target to ", t)
		desired_target = t
		if desired_target in enemies_in_range:
			target = desired_target
	else:
		t = null

#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	assert(get_parent().is_in_group("Unit") or get_parent().is_in_group("Building"))
	if bullet_scene:
		assert(BarrelEnds.get_child_count())
	Reload.wait_time = reload_time
	if get_parent().is_in_group("Building"):
		range_radius += 2
	RangeCircle.shape = CircleShape2D.new()
	RangeCircle.shape.radius = range_radius * 32



func _process(delta : float) -> void:
	if not bullet_scene: return
	if not get_parent().get("built") == null: 
		if not get_parent().built: return
		
	if not enemies_in_range: return
	if not is_instance_valid(desired_target) and desired_target:
		desired_target = null
	elif desired_target in enemies_in_range:
		target = desired_target
	
	if not target and enemies_in_range:
		target = enemies_in_range[randi() % enemies_in_range.size()]
		
	if is_instance_valid(target):
#		if global_rotation_degrees < 0:
#			global_rotation_degrees += 360
		var target_dir : float = rad2deg(global_position.angle_to_point(target.global_position))
#		if target_dir < 0:
#			target_dir += 360
		#print(global_rotation_degrees, )
		if abs(global_rotation_degrees - target_dir) < delta * turn_speed * 2.0:
			global_rotation_degrees = target_dir
		else:
			global_rotation_degrees += Global.FindTurnSide(global_rotation_degrees, target_dir) * delta * turn_speed

		if can_shoot and abs(global_rotation_degrees - target_dir) < 10:
			
			shoot()
	else:
		target = null

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

func shoot() -> void:
	if not can_shoot: return
	if not is_instance_valid(target): return
	var bullet : Node2D = bullet_scene.instance()
	get_parent().get_parent().add_child(bullet)
	bullet.shoot(BarrelEnds.get_children()[barrel].global_position, 
				target.position,
				range_radius * 64.0,
				get_parent())
	can_shoot = false
	barrel = (barrel + 1) % BarrelEnds.get_child_count()
	Reload.start()
	
	

#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_Reload_timeout():
	can_shoot = true


func _on_Range_area_entered(area : Area2D) -> void:
	var parent = area.get_parent()
	if not parent.is_in_group("Unit") and not parent.is_in_group("Building"): return 
	if parent.is_in_group("Building"):
		if not parent.built: return
	if parent.faction == get_parent().faction:
		return
	if target == null:
		target = parent
	enemies_in_range.append(parent)
	#prints("barrel enemy spotted:", parent.name, parent)


func _on_Range_area_exited(area : Area2D) -> void:
	var parent = area.get_parent()
	if not parent in enemies_in_range: return
	enemies_in_range.erase(parent)
	if parent == target:
		if enemies_in_range:
			target = enemies_in_range[randi() % enemies_in_range.size()]
		else:
			target = null
	#prints("barrel enemy lost:", parent.name, parent)
