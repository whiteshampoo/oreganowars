
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node2D
class_name Unit

#-[CONSTANTS]-------------------------------------------------------------------

const REPATH_BASE : int = 10
const REPATH_BASE_MOD : float = 5.0
const REPATH_BLOCK : int = 2
const REPATH_BLOCK_MOD : float = 1.0

const LINE_MOVE : Color = Color(0.0, 1.0, 1.0, 0.25)
const LINE_ATTACK : Color = Color(1.0, 0.0, 0.0, 0.25)

enum STATE {
	STOP, 
	GUARD, 
	PATROL, 
	CHASE, 
	FLEE, 
	SCOUT, 
	RETREAT, 
	SEARCH_AND_DESTROY}

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------

export (String, "null", "red", "blue", "green", "yellow") var faction : String = "null"
export (String, "null", "Tank", "Scout", "Rocket", "Harvester") var type : String = "null"
export var hitpoints_max : float = 100
export var travel_duration : float = 1.0
export var rotation_duration : float = 1.0
export var base_view_distance : int = 0
export var Explosion : PackedScene = null
export var sound_explosion : AudioStreamOGGVorbis = null
export var sound_explosion_db : float = 1.0
export var sound_motor : AudioStreamOGGVorbis = null
export var sound_motor_db : float = 1.0

#-[ONREADY]---------------------------------------------------------------------

onready var Map : MapGenerator = get_parent().get_node("MapGenerator")
onready var Cam : Camera2D = get_parent().Cam
onready var Pathfinder : AStar2D = Map.Pathfinder
onready var Repath : Timer = $Repath
onready var Selector : Sprite = $Selector
onready var DebugPath : Line2D = $DebugPath
onready var Movement : Tween = $Movement
onready var Body : Sprite = $Body
onready var LifeBar : Node2D = $LifeBar
onready var Smoker : CPUParticles2D = $Smoker
onready var ToTarget : Line2D = $ToTarget
onready var Motor : AudioStreamPlayer2D = $Motor

#-[VAR]-------------------------------------------------------------------------

var mouse_over : bool = false
var selected : bool = false
var target : Vector2 = Vector2.ZERO setget set_target
var target_enemy : Node2D = null setget set_target_enemy
var start : bool = false
var next : Vector2 = Vector2.ZERO
var path : PoolVector2Array = PoolVector2Array()
var hitpoints : float = 0.0
var state : int = -1
var pos_retreat : Vector2 = Vector2.ZERO
var pos_guard : Vector2 = Vector2.ZERO
var pos_patrol : Vector2 = Vector2.ZERO
var blocked_tile : Vector2 = Vector2.ZERO
var view_blocks : PoolVector2Array = PoolVector2Array()

var Barrel_Nodes : Array = Array()
var under_attack : Node2D = null
var under_attack_timer : float = 0

var longest_duration : float = travel_duration
var longest_rotation : float = rotation_duration

var __

#-[SETGET METHODS]--------------------------------------------------------------

func set_target(t : Vector2, patrol : bool = false, other_units : Array = []) -> void:
	ToTarget.visible = faction == Global.player_faction
	target = t
	Log.line("Set target point", self, Log.LEVEL.DEBUG)
	if not target: return
	if not target_enemy:
		ToTarget.default_color = LINE_MOVE
	if not patrol:
		if state == STATE.PATROL:
			if not pos_patrol:
				pos_patrol = target
			else:
				state = STATE.GUARD
				pos_guard = target
		else:
			pos_guard = target

	longest_duration = travel_duration
	longest_rotation = rotation_duration
	if state == STATE.GUARD:
		for other in other_units:
			longest_duration = max(longest_duration, other.travel_duration)
			longest_rotation = max(longest_duration, other.rotation_duration)
			
	find_path()


func set_target_enemy(e : Node2D, other_units : Array = []) -> void:
	if not is_instance_valid(e): 
		Log.line("Set target enemy is invalid", self, Log.LEVEL.ERROR)
		e = null
		return
	Log.line("Set target enemy", self, Log.LEVEL.DEBUG, [e])
	ToTarget.default_color = LINE_ATTACK
	target_enemy = e
	set_target(e.position, false, other_units)
	if Barrel_Nodes:
		for b in Barrel_Nodes:
			b.desired_target = e

#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	Log.line("Unit spawned", self, Log.LEVEL.DEBUG, [position, faction])
	assert(faction != "null")
	Body.modulate = Global.FACTION_COLORS[faction]
	align_position()
	__ = Map.block_tile(self, position)
	blocked_tile = position
	target = position
	next = position
	set_hover(false)
	hitpoints = hitpoints_max
	LifeBar.unit_size = Vector2.ONE * 64
	LifeBar.set_hitpoints(hitpoints, hitpoints_max)
	DebugPath.visible = false
	#if faction != Global.player_faction:
	#	find_random_enemy()
	pos_retreat = position
	pos_guard = position
	state = STATE.GUARD
	Motor.stream = sound_motor
	Motor.seek(randf() * sound_motor.get_length())
	Motor.volume_db = -20
	Motor.max_distance = Global.calc_sound_distance(get_viewport_rect().size)
	Motor.attenuation = 2.0
	Motor.bus = "Motors"
	remove_child(Motor)
	Global.add_child(Motor)

	Motor.play()
	for node in get_children():
		if node is Barrel:
			Barrel_Nodes.append(node)
	
	if Barrel_Nodes:
		make_view_array((base_view_distance + Barrel_Nodes[0].range_radius) / 2)
	else:
		make_view_array(base_view_distance)
	




func _process(delta : float) -> void:
	Motor.position = Global.calc_sound_position(position, Cam.position, get_viewport_rect().size)
	if under_attack and not is_instance_valid(under_attack):
		under_attack = null
		under_attack_timer = 0
	if under_attack_timer > 0:
		under_attack_timer -= delta
	else:
		under_attack = null
	
	if not is_instance_valid(target_enemy):
		if target_enemy:
			target_enemy = null
			set_target(position, true)
	else:
		if not target_enemy.visible:
			target_enemy = null
			set_target(position, true)
		else:
			target = target_enemy.position
		
	if target_enemy:
		ToTarget.points[1] = target_enemy.position - position
	elif path:
		ToTarget.points[1] = path[-1] - position
	else:
		ToTarget.visible = false
	#if faction != Global.player_faction and not path:
	#	state = STATE.SEARCH_AND_DESTROY
	if DebugPath.visible:
		DebugPath.global_position = Vector2.ZERO
		DebugPath.global_rotation = 0
	LifeBar.global_rotation = 0
	Selector.global_rotation = 0
	Smoker.global_rotation = 0
	ToTarget.global_rotation = 0
	match state:
		STATE.STOP:
			pass
		STATE.GUARD:
#			if position.distance_to(pos_guard) > 6:
#				if not path:
#					target_enemy = null
#					set_target(pos_guard, true)
#			elif not target_enemy and not path:
#				for b in Barrel_Nodes:
#					if b.enemies_in_range:
#						if is_instance_valid(b.enemies_in_range[0]):
#							set_target_enemy(b.enemies_in_range[0])
#							break
			pass
		STATE.PATROL:
			if not path:
				if position.distance_to(pos_guard) > position.distance_to(pos_patrol):
					set_target(pos_guard, true)
				else:
					set_target(pos_patrol, true)
		STATE.CHASE:
			if not target_enemy and not path:
				for b in Barrel_Nodes:
					if b.enemies_in_range:
						if is_instance_valid(b.enemies_in_range[0]):
							set_target_enemy(b.enemies_in_range[0])
							break
		STATE.FLEE:
			if not path:
				var flee_position : Vector2 = Vector2.ZERO
				for b in Barrel_Nodes:
					for enemy in b.enemies_in_range:
						if not is_instance_valid(enemy): continue
						flee_position += enemy.position.direction_to(position)
				if flee_position:
					flee_position = position + flee_position.normalized() * 64 * 15
					set_target(flee_position.round())
		STATE.SCOUT:
			if not path:
				var new_position = Vector2(Map.height, Map.width) * 64 * randf()
				new_position = position + position.direction_to(new_position) * 64 * 10
				new_position.round()
				set_target(new_position)
		STATE.RETREAT:
			set_target(pos_retreat)
			state = STATE.GUARD
		STATE.SEARCH_AND_DESTROY:
			if not target_enemy:
				for b in Barrel_Nodes:
					if b.enemies_in_range:
						if is_instance_valid(b.enemies_in_range[0]):
							set_target_enemy(b.enemies_in_range[0])
							break
			if not path and not target_enemy:
				var new_position = Vector2(Map.height, Map.width) * 64 * randf()
				new_position = position + position.direction_to(new_position) * 64 * 10
				new_position.round()
				set_target(new_position)
	moving()


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	if not selected:
		return
	if event is InputEventMouseButton:
		if Global.get_global_mouse_position().x > get_viewport_rect().end.x: return
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					if not mouse_over:
						pass#deselect()
				BUTTON_RIGHT:
					if is_instance_valid(Global.enemy_hover):
						state = STATE.GUARD
						set_target_enemy(Global.enemy_hover)
						if Barrel_Nodes:
							for b in Barrel_Nodes:
								b.desired_target = Global.enemy_hover
					else:
						target_enemy = null
						if not state == STATE.PATROL:
							state = STATE.GUARD
						set_target(get_global_mouse_position(), false, Global.selected_units)


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass


func _draw() -> void:
	pass

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func align_position() -> void:
	position.x = int(position.x / 64.0) * 64 + 32
	position.y = int(position.y / 64.0) * 64 + 32

func select() -> void:
	Log.line("Unit selected", self, Log.LEVEL.DEBUG)
	selected = true
	Selector.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	if target_enemy:
		ToTarget.default_color = LINE_ATTACK
		Selector.visible = true
	elif path:
		ToTarget.default_color = LINE_MOVE
		Selector.visible = true
	else:
		Selector.visible = false


func deselect() -> void:
	Log.line("Unit deselected", self, Log.LEVEL.DEBUG)
	selected = false
	Selector.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
	Selector.visible = mouse_over
	ToTarget.visible = false


func find_path() -> void:
	var no_path : bool = path.size() == 0
	Map.unblock_tile(self, blocked_tile)
	var from : int = Pathfinder.get_closest_point(next, true)
	var to : int = Pathfinder.get_closest_point(target)
	path = Pathfinder.get_point_path(from, to)
	__ = Map.block_tile(self, blocked_tile)
	DebugPath.points = path
	if path.size() and no_path:
		start = true
	Repath.start(REPATH_BASE + randf() * REPATH_BASE_MOD)

func turn() -> bool:
	assert(not Movement.is_active())

	var rot : float = Global.get_rotation_for_tween(self, path[0])
	if is_equal_approx(rotation_degrees, rot): return false

	__ = Movement.interpolate_property(self, "rotation_degrees", null,
									rot, abs(rotation_degrees - rot) / 90.0 * longest_rotation, 
									Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	__ = Movement.start()
	return true

func moving() -> void:
	if path and path[0] == position:
		path.remove(0)
	if not path: return
	
	if Movement.is_active(): return
	if turn(): return
	if not Map.block_tile(self, path[0]):
		if path.size() == 1:
			Log.line("Destination blocked, stop movement", self, Log.LEVEL.DEBUG)
			path.remove(0)
			return
		if Repath.time_left > REPATH_BLOCK + REPATH_BLOCK_MOD:
			Repath.start(REPATH_BLOCK + randf() * REPATH_BLOCK_MOD)
		return

	Map.unblock_tile(self, blocked_tile)
	blocked_tile = path[0]
	var move_trans : int = Tween.TRANS_LINEAR
	var move_ease : int = Tween.EASE_IN_OUT
	next = path[0]
	DebugPath.points = path
	var duration : float = get_ground_speed() * longest_duration
	if start and path.size() > 1:
		#__ = Movement.interpolate_property(Motor, )
	#	move_trans = Tween.TRANS_QUAD
	#	move_ease = Tween.EASE_IN
		start = false
# warning-ignore:return_value_discarded
		Movement.interpolate_property(Motor, "volume_db", -20, 
									sound_motor_db, duration, move_trans, move_ease)
# warning-ignore:return_value_discarded
		Movement.interpolate_property(Motor, "pitch_scale", 1, 
							2, duration, move_trans, move_ease)
	if not start and path.size() == 1:
	#	move_trans = Tween.TRANS_QUAD
	#	move_ease = Tween.EASE_OUT
# warning-ignore:return_value_discarded
		Movement.interpolate_property(Motor, "volume_db", null, 
							-20, duration * 2, move_trans, move_ease)
# warning-ignore:return_value_discarded
		Movement.interpolate_property(Motor, "pitch_scale", 2, 
							1, duration * 2, move_trans, move_ease)
	duration *= position.distance_to(next) / 64.0
	__ = Movement.interpolate_property(self, "position", null,
									next, duration, move_trans, move_ease)
	__ = Movement.start()
	path.remove(0)


func set_hover(s : bool) -> void:
	if s:
		mouse_over = true
		Selector.visible = true
		Selector.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		if path:
			ToTarget.visible = true
			
	else:
		mouse_over = false
		Selector.visible = selected
		Selector.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		if not selected:
			ToTarget.visible = false


func die() -> void:
	Log.line("Unit destroyed", self, Log.LEVEL.DEBUG, [position, faction])
	Motor.queue_free()
	if Global.enemy_hover == self:
		Global.enemy_hover = null
	if is_queued_for_deletion(): return
	var explosion : Node2D = Explosion.instance()
	get_parent().add_child(explosion)
	explosion.position = position
	Global.make_sound_2D(sound_explosion,
						position,
						get_parent().Cam.position, 
						get_viewport_rect().size,
						"Explosions",
						sound_explosion_db)
	
	remove_child(Smoker)
	get_parent().add_child(Smoker)
	Smoker.killed(position)
	
	if self in Global.selected_units:
		Global.selected_units.erase(self)
	
	Map.unblock_tile(self, blocked_tile)
	queue_free()

func damage(bullet : Node2D) -> void:
	assert(type != "null")
	if state == STATE.SCOUT:
		set_state(STATE.RETREAT)
	if not under_attack:
		under_attack = bullet.source
		under_attack_timer = 10
	var damage : float = bullet.damage
	match type:
		"Tank":
			damage *= bullet.damage_tank
		"Scout":
			damage *= bullet.damage_scout
		"Rocket":
			damage *= bullet.damage_rocket
	hitpoints -= damage

	LifeBar.set_hitpoints(hitpoints, hitpoints_max)
	Smoker.emitting = hitpoints < hitpoints_max / 2.0
	Smoker.modulate.a = (1.0 - hitpoints / hitpoints_max) * 0.75
	
	if hitpoints <= 0.0:
		die()


func get_ground_speed() -> float:
	var position_id : int = Pathfinder.get_closest_point(position)
	var next_id : int = Pathfinder.get_closest_point(next)
	var ground_speed : float = 0.0
	ground_speed = Pathfinder.get_point_weight_scale(position_id)
	ground_speed += Pathfinder.get_point_weight_scale(next_id)
	return ground_speed / 2.0


func set_state(new_state : int) -> void:
	
	state = new_state
	match state:
		STATE.STOP:
			path = []
		STATE.GUARD:
			pos_guard = next
			path = []
		STATE.PATROL:
			pos_guard = next
			pos_patrol = Vector2.ZERO
			path = []
		STATE.CHASE:
			pass
		STATE.FLEE:
			pass
		STATE.SCOUT:
			path = []
		STATE.RETREAT:
			set_target(pos_retreat)
			state = STATE.GUARD
			pos_guard = path[-1] if path else next
		STATE.SEARCH_AND_DESTROY:
			path = []

func find_random_enemy() -> void:
	var enemies : Array = Array()
	for node in get_parent().get_children():
		if not node.is_in_group("Unit") and not node.is_in_group("Building"): continue
		if node.faction == faction: continue
		enemies.append(node)
	if enemies:
		set_target(enemies[randi() % enemies.size()].position)


func make_view_array(view_distance : int) -> void:
	view_blocks = PoolVector2Array()
	for x in range(-view_distance, view_distance + 1):
		for y in range(-view_distance, view_distance + 1):
			var new_pos : Vector2 = Vector2(x, y)
			if Vector2.ZERO.distance_to(new_pos) <= view_distance:
				view_blocks.append(new_pos)


func uncover_fow(Darkness : TileMap, 
				FogOfWar_Buffer : TileMap, 
				darkness_image : Image, 
				fow_image : Image) -> void:
	for tile in view_blocks:
		var pos : Vector2 = Vector2(tile + position / 64).round() - Vector2.ONE
		Darkness.set_cellv(pos, -1)
		FogOfWar_Buffer.set_cellv(pos, -1)
		if pos.x >= 0 and pos.y >= 0 and pos.x < Map.width and pos.y < Map.height:
			darkness_image.set_pixelv(pos, Color.transparent)
			fow_image.set_pixelv(pos, Color.transparent)

func check_visibility(fow_buffer : TileMap) -> void:
	if fow_buffer.get_cellv(fow_buffer.world_to_map(position)) == -1:
		visible = true
	else:
		visible = false

#-[SIGNAL METHODS]--------------------------------------------------------------

func _on_Movement_tween_all_completed():
	__ = Movement.remove_all()
	align_position()
	next = position
	moving()


func _on_Repath_timeout():
	find_path()



func _on_SelectionArea_mouse_entered():
	if faction != Global.player_faction:
		Global.enemy_hover = self


func _on_SelectionArea_mouse_exited():
	if Global.enemy_hover == self:
		Global.enemy_hover = null
