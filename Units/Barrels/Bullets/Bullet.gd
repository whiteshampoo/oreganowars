
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

export var travel_time : float = 1.0
export var damage : float = 1.0
export var damage_tank : float = 1.0
export var damage_scout : float = 1.0
export var damage_rocket : float = 1.0
export var rocket : bool = false
export var sound_shoot : AudioStreamOGGVorbis = null
export var sound_shoot_db : float = 1.0
export var sound_hit : AudioStreamOGGVorbis = null
export var sound_hit_db : float = 1.0
export var sound_miss : AudioStreamOGGVorbis = null
export var sound_miss_db : float = 1.0
export var Explosion : PackedScene = null
export var sound_explosion : AudioStreamOGGVorbis = null
export var sound_explosion_db : float = 1.0

#-[ONREADY]---------------------------------------------------------------------

onready var T : Tween = $Tween

#-[VAR]-------------------------------------------------------------------------

var target : Array = Array()
var source : Node2D = null

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


func shoot(start : Vector2, end : Vector2, max_distance : float, shooter : Node2D) -> void:
	source = shooter
	Global.make_sound_2D(sound_shoot, 
						start, 
						get_parent().Cam.position, 
						get_viewport_rect().size, 
						"Bullets",
						sound_shoot_db)
	
	position = start
	var mod : float = start.distance_to(end) / max_distance
	end.x += (randf() * 2.0 - 1) * 32.0 * mod
	end.y += (randf() * 2.0 - 1) * 32.0 * mod
	look_at(end)
	var duration : float = start.distance_to(end) * travel_time / 64.0
	var __
	__ = T.interpolate_property(self, "position", null, end,
								duration, 
								Tween.TRANS_LINEAR if not rocket else Tween.TRANS_QUAD, 
								Tween.EASE_IN_OUT if not rocket else Tween.EASE_IN)
	__ = T.start()


func check_visibility(fow_buffer : TileMap) -> void:
	if fow_buffer.get_cellv(fow_buffer.world_to_map(position)) == -1:
		visible = true
	else:
		visible = false

#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_DamageArea_area_entered(area : Area2D) -> void:
	var parent : Node2D = area.get_parent()
	if not parent.is_in_group("Unit") and not parent.is_in_group("Building"):
		return
	if parent in target:
		return
	target.append(parent)
			


func _on_DamageArea_area_exited(area : Area2D) -> void:
	var parent : Node2D = area.get_parent()
	if parent in target:
		target.erase(parent)


func _on_Tween_tween_all_completed():
	#explosion
	queue_free()
	if not target: 
		Global.make_sound_2D(sound_miss, 
						global_position, 
						get_parent().Cam.position, 
						get_viewport_rect().size, 
						"Bullets",
						sound_miss_db)
		return
	if not is_instance_valid(target[-1]) : return
	target[-1].damage(self)
	Global.make_sound_2D(sound_hit, 
						global_position, 
						get_parent().Cam.position, 
						get_viewport_rect().size, 
						"Bullets",
						sound_hit_db)
	if Explosion:
		var explosion : Node2D = Explosion.instance()
		get_parent().add_child(explosion)
		explosion.position = position
	if sound_explosion:
		Global.make_sound_2D(sound_explosion,
							position,
							get_parent().Cam.position, 
							get_viewport_rect().size,
							"Explosions",
							sound_explosion_db)
