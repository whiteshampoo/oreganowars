
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node2D
class_name Building

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------

export (String, "null", "red", "blue", "green", "yellow", "wall") var faction : String = "null"
export var width : int = 1
export var height : int = 1
export var hitpoints_max : float = 100.0
export var Explosion : PackedScene = null
export var sound_explosion : AudioStreamOGGVorbis = null
export var sound_explosion_db : float = 1.0
export var price : int = 100
export var build_duration : float = 5.0
export var buttons_text : PoolStringArray = ["Sell", 
											"Repair", 
											"Tech Update 1", 
											"Tech Update 2"]
export var buttons_tech : PoolIntArray = [0, 0, 0, 1]
export var buttons_price : PoolIntArray = [0, 0, 100, 200]
export var buttons_time : PoolRealArray = [0.0, 0.0, 5.0, 10.0]
export var buttons_spawn : Array = Array()
export var base_view_distance : int = 0

export var sound_building : AudioStreamSample = null
export var sound_unit : AudioStreamSample = null
export var sound_tech : AudioStreamSample = null


#-[ONREADY]---------------------------------------------------------------------

onready var Visual : Sprite = $Visual
onready var LifeBar : Node2D = $LifeBar
onready var GroundShape : CollisionShape2D = $SelectionArea/Shape
onready var NearbyShape : CollisionShape2D = $Nearby/Shape
onready var Map : MapGenerator = get_parent().get_node("MapGenerator")
onready var Pathfinder : AStar2D = Map.Pathfinder
onready var Smoker : CPUParticles2D = $Smoker
onready var Selector : Sprite = $Selector
onready var RepairTimer : Timer = $Repair
onready var Progress : Tween = $Progress

onready var Player : AudioStreamPlayer = $Player

#-[VAR]-------------------------------------------------------------------------

var occupation : PoolVector2Array = PoolVector2Array()
var output_points : PoolVector2Array = PoolVector2Array()
var hitpoints : float = 0
var built : bool = true
var mouse_over : bool = false
var selected : bool = false
var progress : float = 0.0
var work : String = ""
var button_update : bool = false
var repairing : bool = false
var tech : int = 0
var do_value : int = 0
var build_finished : bool = false
var nearby : Array = Array()
var view_blocks : PoolVector2Array = PoolVector2Array()
var Barrel_Nodes : Array = Array()
var under_attack : Node2D = null
var under_attack_timer : float = 0

#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	Log.line("Building spawned", self, Log.LEVEL.DEBUG, [position, faction])
	assert(sound_building)
	assert(sound_tech)
	assert(sound_unit)
	assert(faction != "null")
	Visual.modulate = (Global.FACTION_COLORS[faction] + Color.white + Color.white) / 3.0
	align_position()
	hitpoints = hitpoints_max
	LifeBar.unit_size = Vector2(width * 64, height * 64)
	
	GroundShape.position = Vector2(width, height) * 32 - Vector2(32, 32)
	GroundShape.shape.extents = Vector2(width, height) * 32 
	NearbyShape.position = GroundShape.position
	NearbyShape.shape.extents = GroundShape.shape.extents + Vector2.ONE * 64 * 1.5
	Selector.position = GroundShape.position 
	Selector.scale = Vector2(width, height)
	
	calc_points()
	Smoker.position = occupation[randi() % occupation.size()]
	if built:
		block_occupation_on_map()
	else:
		Global.placing_building = self
	
	for node in get_children():
		if node is Barrel:
			Barrel_Nodes.append(node)
	
	if Barrel_Nodes:
		make_view_array((base_view_distance + Barrel_Nodes[0].range_radius) / 2)
	else:
		make_view_array(base_view_distance)
	


func _process(delta : float) -> void:
	if under_attack and not is_instance_valid(under_attack):
		under_attack = null
		under_attack_timer = 0
	if under_attack_timer > 0:
		under_attack_timer -= delta
	else:
		under_attack = null
		
	if built == false and faction == Global.player_faction:
		position = get_global_mouse_position()
		align_position()
		if check_build_possible():
			modulate = Color(1.0, 1.0, 1.0, 0.5)
		else:
			modulate = Color(1.0, 0.0, 0.0, 0.5)


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				if not built and faction == Global.player_faction:
					build()
			if event.button_index == BUTTON_RIGHT and not built:
				Global.faction_credits[faction] += price
				if Global.placing_building == self:
					Global.placing_building = null
				queue_free()


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

func calc_points() -> void:
	for x in width:
		for y in height:
			occupation.append(Vector2(x, y) * 64)
	
	for x in width:
		output_points.append(Vector2(x, -1) * 64)
		output_points.append(Vector2(x, height) * 64)

	for y in height:
		output_points.append(Vector2(-1, y) * 64)
		output_points.append(Vector2(width, y) * 64)


func check_map_point(pos : Vector2) -> bool:
	return not pos in Map.blocked_tiles.keys()


func check_map_points() -> bool:
	for pos in occupation:
		if not check_map_point(pos + position): return false
	return true


func check_path_point(pos : Vector2) -> bool:
	var id : int = Pathfinder.get_closest_point(pos + position)
	return pos + position == Pathfinder.get_point_position(id)


func check_path_points() -> bool:
	for pos in occupation:
		if not check_path_point(pos): return false
	return true


func check_build_possible() -> bool:
	if not check_map_points(): return false
	if not check_path_points(): return false
	return nearby.size() > 0


func check_drop_possible(pos : Vector2) -> bool:
	if not check_map_point(pos): return false
	if not check_path_point(pos): return false
	return true


func block_occupation_on_map() -> void:
	for pos in occupation:
# warning-ignore:return_value_discarded
# warning-ignore:return_value_discarded
# warning-ignore:return_value_discarded
		Map.block_tile(self, pos + position)


func unblock_occupation_on_map() -> void:
	for pos in occupation:
		Map.unblock_tile(self, pos + position)


func build() -> void:
	if not check_build_possible() and faction == Global.player_faction: return # faction <- AI-hack
	if Global.placing_building == self:
		Global.placing_building = null
	built = true
	modulate = Color.white
	block_occupation_on_map()
	for block in occupation: #remove oregano
		Map.remove_oregano(position + block)
	Log.line("Building built", self, Log.LEVEL.DEBUG, [self.position])
	return 


func die() -> void:
	Log.line("Building destroyed", self, Log.LEVEL.DEBUG, [position, faction])
	if is_queued_for_deletion(): return
	for pos in occupation:
		var explosion : Node2D = Explosion.instance()
		get_parent().add_child(explosion)
		explosion.position = position + pos
	Global.make_sound_2D(sound_explosion,
						position,
						get_parent().Cam.position, 
						get_viewport_rect().size,
						"Explosions",
						sound_explosion_db)
	
	remove_child(Smoker)
	get_parent().add_child(Smoker)
	Smoker.killed(position)
	
	if self == Global.selected_building:
		Global.selected_building = null
	
	unblock_occupation_on_map()
	queue_free()


func damage(bullet : Node2D) -> void:
	if not under_attack:
		under_attack = bullet.source
		under_attack_timer = 10
	if not built: return
	var damage : float = bullet.damage
	hitpoints -= damage
	Smoker.emitting = hitpoints < hitpoints_max / 2.0
	LifeBar.set_hitpoints(hitpoints, hitpoints_max)
	if hitpoints <= 0.0:
		die()

func set_hover(s : bool) -> void:
	if s:
		mouse_over = true
		Selector.visible = true
		Selector.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		mouse_over = false
		Selector.visible = selected
		Selector.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func select() -> void:
	Log.line("Building Selected", self, Log.LEVEL.DEBUG)
	selected = true
	Selector.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	Selector.visible = true


func deselect() -> void:
	Log.line("Building Deselected", self, Log.LEVEL.DEBUG)
	selected = false
	Selector.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
	Selector.visible = mouse_over
	
func spawn_unit(packed_unit : PackedScene) -> bool:
	var try_positions : Array = output_points
	var drop_pos : Vector2 = Vector2.ZERO
	while try_positions:
		var try_pos = try_positions[randi() % try_positions.size()]
		if check_drop_possible(try_pos):
			drop_pos = try_pos
			break
		try_positions.erase(try_pos)
	if not drop_pos:
		return false
	var unit : Node2D = packed_unit.instance()
	unit.faction = faction
	unit.position = position + drop_pos
	get_parent().add_child(unit)
	return true


func spawn_building(packed_building : PackedScene) -> Node2D:
	var building : Node2D = packed_building.instance()
	building.built = false
	building.faction = faction
	get_parent().add_child(building)
	return building

func Sell(_value : int) -> void:
	Global.faction_credits[faction] += int(price * hitpoints / hitpoints_max)
	deselect()
	unblock_occupation_on_map()
	queue_free()


func Repair(_value : int) -> void:
	if work != "": return
	button_update = true
	if not repairing:
		repairing = true
		work = "Repair"
		RepairTimer.start()
		progress = hitpoints / hitpoints_max * 100.0
	else:
		repairing = false
		work = ""
		RepairTimer.stop()
		progress = 0


func Tech_Update(value : int) -> void:
	if tech < buttons_tech[value]: return
	if work == "" and buttons_price[value] > Global.faction_credits[faction]: return
	button_update = true
	if not work == "Tech Update " + str(tech + 1):
		work = "Tech Update " + str(tech + 1)
		Global.faction_credits[faction] -= buttons_price[value]
		do_value = value
		progress = 0.0
# warning-ignore:return_value_discarded
		Progress.interpolate_property(self, "progress", 
									0, 100, buttons_time[value] / 2.0, 
									Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		Progress.start()
	else:
		Progress.remove_all()
		if progress >= 100.0:
			if faction == Global.player_faction:
				Player.stream = sound_tech
				Player.play()
			tech += 1
			#buttons_text.remove(do_value)
			buttons_tech[value] = 999#.remove(do_value)
			#buttons_price.remove(do_value)
			#buttons_time.remove(do_value)
			#buttons_spawn.remove(do_value)
		else:
			Global.faction_credits[faction] += buttons_price[value]
		work = ""
		progress = 0



func Tech_Update_1(value : int) -> void:
	Tech_Update(value)


func Tech_Update_2(value : int) -> void:
	Tech_Update(value)


func Build_Unit(value : int) -> void:
	#if work != "": return
	if tech < buttons_tech[value]: return
	if work == "" and buttons_price[value] > Global.faction_credits[faction]: return
	Log.line("Building unit start", self, Log.LEVEL.DEBUG, [buttons_text[value]])
	button_update = true
	if not work == buttons_text[value]:
		work = buttons_text[value]
		Global.faction_credits[faction] -= buttons_price[value]
		do_value = value
		progress = 0.0
# warning-ignore:return_value_discarded
		Progress.interpolate_property(self, "progress", 
									0, 100, buttons_time[value] / 2.0, 
									Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
		Progress.start()
	else:
		Log.line("Building unit finished", self, Log.LEVEL.DEBUG, [buttons_text[value]])
# warning-ignore:return_value_discarded
		Progress.remove_all()
		if progress >= 100.0:
			if not spawn_unit(buttons_spawn[do_value]):
# warning-ignore:return_value_discarded
				Progress.interpolate_property(self, "progress", 
											90, 100, buttons_time[value] / 9.0, 
											Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
				Progress.start()
				return
			if faction == Global.player_faction:
				Player.stream = sound_unit
				Player.play()
		else:
			Global.faction_credits[faction] += buttons_price[value]
		work = ""
		progress = 0


func Build_Building(value : int) -> Node2D:
	#if work != "": return
	if tech < buttons_tech[value]: return null
	if work == "" and buttons_price[value] > Global.faction_credits[faction]: return null
	button_update = true
	if not work == buttons_text[value]:
		work = buttons_text[value]
		Global.faction_credits[faction] -= buttons_price[value]
		do_value = value
		progress = 0.0
# warning-ignore:return_value_discarded
		Progress.interpolate_property(self, "progress", 
									0, 100, buttons_time[value] / 2.0, 
									Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
		Progress.start()
	else:
		var return_building = null
# warning-ignore:return_value_discarded
		Progress.remove_all()
		if progress >= 100.0:
			if not build_finished:
				if faction == Global.player_faction:
					Player.stream = sound_building
					Player.play()
				build_finished = true
				return null
			else:
				return_building = spawn_building(buttons_spawn[do_value])
				build_finished = false
		else:
			Global.faction_credits[faction] += buttons_price[value]
		work = ""
		progress = 0
		return return_building
	return null


func make_view_array(view_distance : int) -> void:
	view_blocks = PoolVector2Array()
	for pos in occupation:
		pos = Vector2(pos / 64).round()
		for x in range(-view_distance + 1, view_distance):
			for y in range(-view_distance + 1, view_distance):
				var new_pos : Vector2 = Vector2(x, y) + pos
				if pos.distance_to(new_pos) <= view_distance:
					if not new_pos in view_blocks:
						view_blocks.append(new_pos)



func uncover_fow(Darkness : TileMap, 
				FogOfWar_Buffer : TileMap, 
				darkness_image : Image, 
				fow_image : Image) -> void:
	if not built: return
	for tile in view_blocks:
		var pos : Vector2 = Vector2(tile + position / 64).round() - Vector2.ONE
		Darkness.set_cellv(pos, -1)
		FogOfWar_Buffer.set_cellv(pos, -1)
		if pos.x >= 0 and pos.y >= 0 and pos.x < Map.width and pos.y < Map.height:
			darkness_image.set_pixelv(pos, Color.transparent)
			fow_image.set_pixelv(pos, Color.transparent)

#-[SIGNAL METHODS]--------------------------------------------------------------



func _on_Repair_timeout():
	if hitpoints == hitpoints_max or Global.faction_credits[faction] < int(price * 0.05):
		repairing = false
		work = ""
		RepairTimer.stop()
		progress = 0.0
	else:
		if Global.faction_credits[faction] >= int(price * 0.05):
			Global.faction_credits[faction] -= int(price * 0.05)
			hitpoints = min(hitpoints + hitpoints_max * 0.05, hitpoints_max)
			progress = hitpoints / hitpoints_max * 100.0
	LifeBar.set_hitpoints(hitpoints, hitpoints_max)
	Smoker.emitting = hitpoints < hitpoints_max / 2.0
	button_update = true
			


func _on_Progress_tween_all_completed():
	call(work.replace(" ", "_"), do_value)


func _on_Nearby_area_entered(area : Area2D) -> void:
	if area.name == "Nearby":
		if area.get_parent().faction == faction:
			nearby.append(area)


func _on_Nearby_area_exited(area : Area2D) -> void:
	if area in nearby:
		nearby.erase(area)


func _on_SelectionArea_mouse_entered():
	if faction != Global.player_faction:
		Global.enemy_hover = self


func _on_SelectionArea_mouse_exited():
	if Global.enemy_hover == self:
		Global.enemy_hover = null
