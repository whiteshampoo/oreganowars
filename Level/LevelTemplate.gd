
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

export var fog_of_war_enabled : bool = false
export var darkness_enabled : bool = false
export var width : int = 64
export var height : int = 64
export var players : int = 4

#-[ONREADY]---------------------------------------------------------------------

onready var Map : MapGenerator = $MapGenerator
onready var Cam : Camera2D = $GameCamera
onready var SelectionBox : Area2D = $SelectionBox
onready var Darkness : TileMap = $Darkness
onready var FogOfWar_Buffer1 : TileMap = $FogOfWar_Buffer1
onready var FogOfWar_Buffer2 : TileMap = $FogOfWar_Buffer2

#-[VAR]-------------------------------------------------------------------------

var minimap_overlay : Image = Image.new()
var minimap_update : float = 0.15
var fog_of_war_update : float = 0.50
var fog_of_war_buffer : bool = false
var fog_of_war_thread : Thread = Thread.new()
var fog_of_war_update_line : int  = 0
var fog_of_war_overlay : Image = Image.new()
var darkness_overlay : Image = Image.new()



#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	if Global.new_game_map_size != 0:
		width = Global.new_game_map_size
		height = Global.new_game_map_size
		players = Global.new_game_enemies + 1
		darkness_enabled = Global.new_game_darkness
		fog_of_war_enabled = Global.new_game_fog_of_war

	randomize()
	Map.generate_map(width, height, players, randi())
	for i in Map.spawnpoints.size():
		create_spawn_location(Map.spawnpoints[i], Global.FACTIONS[i])
	minimap_overlay.create(Map.width, Map.height, false, Image.FORMAT_RGBA8)
	darkness_overlay.create(Map.width, Map.height, false, Image.FORMAT_RGBA8)
	fog_of_war_overlay.create(Map.width, Map.height, false, Image.FORMAT_RGBA8)
	
	if darkness_enabled: 
		darkness_overlay.fill(Color.black)
		
	Darkness.visible = darkness_enabled
	
	if fog_of_war_enabled: 
		fog_of_war_overlay.fill(Color.black)

	FogOfWar_Buffer1.visible = fog_of_war_enabled
	FogOfWar_Buffer2.visible = fog_of_war_enabled
		
	Cam.map_size.x = Map.width * 64
	Cam.map_size.y = Map.height * 64
	
	var player_units : Array = Array()

	for node in get_children():
		if not node.is_in_group("Unit") and not node.is_in_group("Building"): continue
		if node.is_in_group("Unit") and fog_of_war_enabled:
			node.check_visibility(FogOfWar_Buffer2 if fog_of_war_buffer else FogOfWar_Buffer1)
		if node.faction != Global.player_faction: continue
		player_units.append(node)
	var player_pos : Vector2 = Vector2.ZERO
	for unit in player_units:
		player_pos += unit.position
	#rint(player_pos / player_units.size())
	Cam.CamMove.remove_all()
	Cam.CamZoom.remove_all()
	Cam.position = player_pos / player_units.size()
	
	for x in Map.width:
		for y in Map.height:
			if darkness_enabled: Darkness.set_cell(x, y, 0)
			if fog_of_war_enabled:
				FogOfWar_Buffer1.set_cell(x, y, 0)
				FogOfWar_Buffer2.set_cell(x, y, 0)
	
	#fog_of_war_thread.start(self, "fog_of_war_worker", null, Thread.PRIORITY_NORMAL)

func _process(delta : float) -> void:
	minimap_update += delta
	fog_of_war_update += delta
	if minimap_update >= 0.1:
		minimap_update -= 0.1
		minimap_overlay.fill(Color.transparent)
		minimap_overlay.lock()
		
		var r : Rect2 = get_viewport_rect()
		r.position = ((Cam.position - r.size / 2 * Cam.zoom.x) / 64)
		r.end = (Cam.position + r.size / 2 * Cam.zoom.y) / 64
		r.position.x = clamp(int(r.position.x), 0, Map.width - 1)
		r.position.y = clamp(int(r.position.y), 0, Map.height - 1)
		r.end.x = clamp(int(r.end.x), 0, Map.width - 1)
		r.end.y = clamp(int(r.end.y), 0, Map.height - 1)
		var c : Color = Color(1.0, 1.0, 1.0, 0.5)

		for x in r.size.x:
			var px : int = r.position.x + x
			minimap_overlay.set_pixel(px, int(r.position.y), c)
			minimap_overlay.set_pixel(px, int(r.end.y), c)
			
		for y in r.size.y + 1:
			var py : int = r.position.y + y
			minimap_overlay.set_pixel(int(r.position.x), py, c)
			minimap_overlay.set_pixel(int(r.end.x), py, c)
		
		var fow_buffer : TileMap = null
		if fog_of_war_enabled:
			fow_buffer = FogOfWar_Buffer2 if fog_of_war_buffer else FogOfWar_Buffer1
		else:
			fow_buffer = Darkness
		
		for unit in get_children():
			if fog_of_war_enabled:
				if unit.is_in_group("Unit") or unit.is_in_group("Bullet") or unit.is_in_group("Explosion") or unit.is_in_group("Smoker"):
					unit.check_visibility(FogOfWar_Buffer2 if fog_of_war_buffer else FogOfWar_Buffer1)
			if unit.is_in_group("Building"):
				if not unit.built: continue
				var pos : Vector2 = Vector2(unit.position / 64 - Vector2.ONE / 2).round()
				for x in unit.width:
					for y in unit.height:
						if pos.x < 0 or pos.y < 0 or pos.x >= width  or pos.y >= height: continue
						if not fow_buffer.get_cell(pos.x + x, pos.y + y): continue
						minimap_overlay.set_pixel(pos.x + x, pos.y + y, 
												Global.FACTION_COLORS[unit.faction])
			elif unit.is_in_group("Unit"):
				var pos : Vector2 = Vector2(unit.position / 64 - Vector2.ONE / 2).round()
				if pos.x < 0 or pos.y < 0 or pos.x >= width  or pos.y >= height: continue
				if not fow_buffer.get_cellv(pos): continue
				minimap_overlay.set_pixelv(pos, Global.FACTION_COLORS[unit.faction])
		minimap_overlay.unlock()
	
	#if fog_of_war_update >= 0.1:
	#	fog_of_war_update -= 0.1
	if darkness_enabled or fog_of_war_enabled:
		fog_of_war_worker()
#
#		if not fog_of_war_thread.is_active():
#			fog_of_war_thread.start(self, "fog_of_war_worker", null, Thread.PRIORITY_NORMAL)
#		else:
#			fog_of_war_thread.wait_to_finish()


func _physics_process(_delta : float) -> void:
	pass


func _input(_event : InputEvent) -> void:
	pass


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass


func _draw() -> void:
	#draw_rect(Cam.dimension, Color.white, false, 2.0)
	pass


func _exit_tree() -> void:
	pass#fog_of_war_thread.wait_to_finish()

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func create_spawn_location(location : Vector2, faction : String) -> void:
	var hq : Node2D = preload("res://Buildings/HQ/HQ.tscn").instance()
	var units : Array = [
		preload("res://Units/Scout/Scout_Tier_1.tscn").instance(),
		preload("res://Units/Scout/Scout_Tier_1.tscn").instance(),
		preload("res://Units/Light/Light_Tier_1.tscn").instance(),
		preload("res://Units/Rocket/Rocket_Tier_1.tscn").instance()
	]
	hq.position = location
	hq.built = true
	hq.faction = faction
	add_child(hq)
	var start_angle : float = randf() * 360.0
	var unit_angle : float = 360.0 / units.size()
	for u in units:
		u.position = location + Vector2.RIGHT.rotated(deg2rad(start_angle)) * 5 * 64
		start_angle += unit_angle
		u.faction = faction
		add_child(u)

func fog_of_war_worker() -> void:
	var Buffer : TileMap = FogOfWar_Buffer1 if fog_of_war_buffer else FogOfWar_Buffer2
	for x in Map.width:
		for y in int(Map.height / 8.0):
			Buffer.set_cell(x, fog_of_war_update_line + y, 0)
	fog_of_war_update_line += int(Map.height / 8.0)
	
	if fog_of_war_update_line >= Map.height:
		fog_of_war_update_line = 0
		
		if fog_of_war_enabled: fog_of_war_overlay.fill(Color(0.0, 0.0, 0.0, 0.5))
		darkness_overlay.lock()
		fog_of_war_overlay.lock()
		
		for unit in get_children():
			if not unit.is_in_group("Unit") and not unit.is_in_group("Building"): continue
			if not unit.faction == Global.player_faction: continue
			unit.uncover_fow(Darkness, Buffer, darkness_overlay, fog_of_war_overlay)
			
		darkness_overlay.unlock()
		fog_of_war_overlay.unlock()
		
		if fog_of_war_enabled:
			FogOfWar_Buffer1.visible = true if fog_of_war_buffer else false
			FogOfWar_Buffer2.visible = false if fog_of_war_buffer else true
			fog_of_war_buffer = not fog_of_war_buffer

#-[SIGNAL METHODS]--------------------------------------------------------------
