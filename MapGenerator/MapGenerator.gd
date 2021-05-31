
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node2D
class_name MapGenerator
tool

#-[CONSTANTS]-------------------------------------------------------------------

const TREES : Array = [0, 1, 2, 3, 4]
const ROCKS : Array = [5, 6, 7]
const GRASS_TREE_CHANCE = 0.015
const GRASS_ROCK_CHANCE = 0.005
const SAND_TREE_CHANCE = 0.001
const SAND_ROCK_CHANCE = 0.01
const DIRT_TREE_CHANCE = 0.001
const DIRT_ROCK_CHANCE = 0.02

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------

export var width : int = 30 setget set_width
export var height : int = 16 setget set_height
export var map_seed : int = 0 setget set_map_seed
export var players : int = 4

#-[ONREADY]---------------------------------------------------------------------

onready var Ground : TileMap = $Ground
onready var Grass : TileMap = $Grass
onready var Sand : TileMap = $Sand
onready var Rock : TileMap = $Rock
onready var Nature : TileMap = $Nature

#-[VAR]-------------------------------------------------------------------------

var Noise : OpenSimplexNoise = OpenSimplexNoise.new()
var Pathfinder : AStar2D = AStar2D.new()
var blocked_tiles : Dictionary = Dictionary()
var minimap : Image = Image.new()
var minimap_oregano : Image = Image.new()
var spawnpoints : PoolVector2Array = PoolVector2Array()
var spawn_start_angle = 0
var spawn_player_angle = 0
var oregano_dict : Dictionary = Dictionary()

#-[SETGET METHODS]--------------------------------------------------------------

func set_width(w : int) -> void:
	assert(w > 0)
	if w > 256:
		w = 256
	width = w
	#generate_map()


func set_height(h : int) -> void:
	assert(h > 0)
	if h > 256:
		h = 256
	height = h
	#generate_map()

func set_map_seed(s : int) -> void:
	map_seed = s
	generate_map()

#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	pass#generate_map()


func _process(_delta : float) -> void:
	pass


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	pass


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func clear_map() -> void:
	if not Ground:
		return
	Ground.clear()
	Grass.clear()
	Sand.clear()
	Rock.clear()
	Nature.clear()
	Pathfinder.clear()

func get_shampoo_noise(x : float, y : float, shampoo : float) -> float:
	var a : float = (Noise.get_noise_3d(x, y, 0) + 1.0) / 2.0
	var b : float = (Noise.get_noise_3d(x, y, shampoo) + 1.0) / 2.0
	return (a + b) / 2.0

func generate_layer(Layer : TileMap, 
					layer_seed : int, 
					octaves : int, 
					period : int, 
					persistance : float,
					lucanarity : float,
					shampoo : float,
					coverage : float,
					border : bool = false) -> void:
	assert(coverage >= 0.0 and coverage <= 1.0)
	if not Layer:
		return
	Noise.seed = layer_seed
	Noise.octaves = octaves
	Noise.period = period
	Noise.persistence = persistance
	Noise.lacunarity = lucanarity
	
	for x in width:
		for y in height:
			if (x == 0 or y == 0 or x == width -1 or y == height - 1) and border:
				Layer.set_cell(x, y, 0)
			else:
				Layer.set_cell(x, y, 0 if get_shampoo_noise(x, y, shampoo) < coverage else -1)
	Layer.update_bitmask_region()


func calc_chance(type : float, noise : float) -> bool:
	return noise > 0.5 - type and noise < 0.5 + type


func calc_rock_or_tree(rock, tree, noise) -> int:
	var m : float = randf() * (rock + tree)
	if rock > m:
		if calc_chance(rock, noise):
			return ROCKS[randi() % ROCKS.size()]
	else:
		if calc_chance(tree, noise):
			return TREES[randi() % TREES.size()]
	return -1

func generate_nature() -> void:
	Noise.seed = map_seed - 1
	Noise.octaves = 2
	Noise.period = 8
	Noise.persistence = 0.5
	Noise.lacunarity = 2
	
	var a : float = 0
	var b : int = -1
	for x in width:
		for y in height:
			if Rock.get_cell(x, y) == 0:
				continue
				
			a = get_shampoo_noise(x, y, 0)
			if Grass.get_cell(x, y) == 0:
				b = calc_rock_or_tree(GRASS_ROCK_CHANCE, GRASS_TREE_CHANCE, a)
				if b != -1:
					Nature.set_cell(x, y, b)
				continue
				
			if Sand.get_cell(x, y) == 0:
				b = calc_rock_or_tree(SAND_ROCK_CHANCE, SAND_TREE_CHANCE, a)
				if b != -1:
					Nature.set_cell(x, y, b)
				continue
			
			#DIRT
			b = calc_rock_or_tree(DIRT_ROCK_CHANCE, DIRT_TREE_CHANCE, a)
			if b != -1:
				Nature.set_cell(x, y, b)

func make_minimap() -> void:
	minimap.create(width, height, false, Image.FORMAT_RGBA8)
	minimap_oregano.create(width, height, false, Image.FORMAT_RGBA8)
	minimap.fill(Color("#bb8044"))
	minimap_oregano.fill(Color.transparent)
	minimap.lock()
	minimap_oregano.lock()
	for x in width:
		for y in height:
			if Nature.get_cell(x, y) in range(0, 8):
				minimap.set_pixel(x, y, Color.lightgray)
							
			elif Rock.get_cell(x, y) == 0:
				minimap.set_pixel(x, y, Color.darkgray)

			elif Grass.get_cell(x, y) == 0:
				minimap.set_pixel(x, y, Color("#2ecc71") / 2.0 + Color.gray / 2.0)

			elif Sand.get_cell(x, y) == 0:
				minimap.set_pixel(x, y, Color("#e6d6b3") / 2.0 + Color.gray / 2.0)
				
			if Nature.get_cell(x, y) == 8:
				minimap_oregano.set_pixel(x, y, Color.darkgreen  / 2.0 + Color.gray / 2.0)
	minimap.unlock()
	minimap_oregano.unlock()

func remove_oregano(pos : Vector2) -> void:
	if pos in oregano_dict:
# warning-ignore:return_value_discarded
		oregano_dict.erase(pos)
		pos = Nature.world_to_map(pos)
		minimap_oregano.lock()
		minimap_oregano.set_pixelv(Vector2(pos / 64).round(), Color.transparent)
		minimap_oregano.unlock()
		Nature.set_cellv(pos, -1)
		Nature.update_bitmask_area(pos)

func make_oregano_blob(pos : Vector2, size : Vector2, cash : float) -> void:
	pos = pos.round()
	size = size.round()
	var x_mod : float = size.x / max(size.x, size.y)
	var y_mod : float = size.y / max(size.x, size.y)
	for x in range(-size.x, size.x + 1):
		for y in range(-size.y, size.y + 1):
			if Vector2(x / x_mod, y / y_mod).length() > max(size.x, size.y): continue
			var blob : Vector2 = pos + Vector2(x, y)
			blob = blob.round()
			if blob.x < 0 or blob.y < 0 or blob.x >= width or blob.y >= height: continue
			if Rock.get_cellv(blob) == -1 and Nature.get_cellv(blob) == - 1:
				Nature.set_cellv(blob, 8)
				oregano_dict[blob * 64 + Vector2.ONE * 32] = cash

func generate_oregano() -> void:
	if spawn_player_angle == 0:
		spawn_player_angle = 90
	oregano_dict = Dictionary()
	var size_mod : float = (width + height) / 256.0
	size_mod *= 0.5#2 / (360.0 / spawn_player_angle)
	for i in int(360.0 / spawn_player_angle) * 2:
		for j in range(0, 4):
			var angle : float = spawn_start_angle + (spawn_player_angle / 2.0) * i
			angle += (spawn_player_angle / 4.0) * (j + 1) 
			var pos : Vector2 = Vector2.RIGHT.rotated(deg2rad(angle))
			pos.x *= width * (0.25 + j * 0.25) * 0.5
			pos.y *= height * (0.25 + j * 0.25) * 0.5
			pos.x += width / 2.0
			pos.y += height / 2.0
			pos = pos.round()
			
# warning-ignore:unused_variable
			for a in range(2, 4 + randi() % 3):
				make_oregano_blob(pos + Vector2(rand_range(-5, 6), rand_range(-5, 6)),
									Vector2(rand_range(3, 7), rand_range(3, 7)) * size_mod,
									200.0 / size_mod)
	#rint("dict: ", oregano_dict.size(), " cash: ", oregano_dict.size() * 200.0 / size_mod, " (", 200.0 / size_mod, ")")
	Log.line("Oregano", self, Log.LEVEL.INFO, [oregano_dict.size(), oregano_dict.size() * 200.0 / size_mod, 200.0 / size_mod])
	Nature.update_bitmask_region()


func calc_path_id(x, y, mod_x = 0, mod_y = 0) -> int:
	return x + mod_x + width * (y + mod_y)


func generate_pathfinding() -> void:
	Pathfinder.clear()
	for x in width:
		for y in height:
			if x == 0 or y == 0 : continue
			if x == width - 1 or y == height - 1: continue
			if Rock.get_cell(x, y) == 0 or Nature.get_cell(x, y) in range(0, 8):
				continue
				
			var weight : float = 1.5 # Slow on dirt
			if Grass.get_cell(x, y) == 0: weight = 1.0 # Fast on grass
			elif Sand.get_cell(x, y) == 0: weight = 2.0 #very slow on sand
				
			Pathfinder.add_point(calc_path_id(x, y), Vector2(x  * 64 + 32, y * 64 + 32), weight)
			for a in range(-1, 2):
				for b in range(-1, 2):
					if a == 0 and b == 0:# or a != 0 and b != 0:
						continue # not self and not diagonal 
					if Pathfinder.has_point(calc_path_id(x, y, a, b)):
						Pathfinder.connect_points(calc_path_id(x, y),
												calc_path_id(x, y, a, b))

func bad_deleted_object_hack():
	for tile in blocked_tiles.keys():
		if not is_instance_valid(blocked_tiles[tile]):
			Log.line("Remove deleted blocked_tile", self, Log.LEVEL.ERROR, [tile])
# warning-ignore:return_value_discarded
			blocked_tiles.erase(tile)

func block_tile(blocker : Node2D, pos : Vector2) -> bool:
	bad_deleted_object_hack()
	var id : int = Pathfinder.get_closest_point(pos, true)
	assert(pos == Pathfinder.get_point_position(id))
	if pos in blocked_tiles:
		return false
	blocked_tiles[pos] = blocker
	Pathfinder.set_point_disabled(id, true)
	return true

func unblock_tile(unblocker : Node2D, pos : Vector2) -> void:
	bad_deleted_object_hack()
	var id : int = Pathfinder.get_closest_point(pos, true)
	assert(pos == Pathfinder.get_point_position(id))
	assert(pos in blocked_tiles, str(pos))
	#assert(blocked_tiles[pos] == unblocker, str(unblocker) + " " + str(blocked_tiles[pos]))
	if not blocked_tiles[pos] == unblocker: 
		Log.line("unblocker-fail", self, Log.LEVEL.ERROR, [blocked_tiles[pos], unblocker, pos])
		if not is_instance_valid(unblocker) or unblocker.is_queued_for_deletion():
			Log.line("unblocker is invalid", self, Log.LEVEL.ERROR)
		if not is_instance_valid(blocked_tiles[pos]) or blocked_tiles[pos].is_queued_for_deletion():
			Log.line("old blocker is invalid", self, Log.LEVEL.ERROR)
		return
		
# warning-ignore:return_value_discarded
	blocked_tiles.erase(pos)
	Pathfinder.set_point_disabled(id, false)

func tidy_spawnpoint(pos : Vector2, radius : int) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if Vector2.ZERO.distance_to(Vector2(x, y)) <= radius:
				Rock.set_cell(int(pos.x + x), int(pos.y + y), -1)
				Nature.set_cell(int(pos.x + x), int(pos.y + y), -1)
	Rock.update_bitmask_region()

func make_spawnpoints(pn : int) -> void:
	if pn == 0: return
	spawn_start_angle = randf() * 360.0
	spawn_player_angle = 360.0 / pn
	for i in pn:
		var pos : Vector2 = Vector2.RIGHT.rotated(deg2rad(spawn_start_angle + spawn_player_angle * i))
		pos.x *= width * 0.75 * 0.5
		pos.y *= height * 0.75 * 0.5
		pos.x += width / 2.0
		pos.y += height / 2.0
		pos = pos.round()
		tidy_spawnpoint(pos, 6)
		pos *= 64
		spawnpoints.append(pos)
		

func generate_map(map_width : int = 0, map_height : int = 0, map_players : int = 0, new_map_seed : int = 0) -> void:
	if map_width: width = map_width
	if map_height: height = map_height
	if map_players: players = map_players
	if new_map_seed: map_seed = new_map_seed
	seed(map_seed)
	if not Ground:
		return
	Log.line("Generate new map", self, Log.LEVEL.INFO, [width, height, map_seed])
	var time : int = OS.get_ticks_msec()
	clear_map()
	Log.line("Map cleared", self, Log.LEVEL.INFO, [OS.get_ticks_msec() - time])
	time = OS.get_ticks_msec()
	generate_layer(Ground, 0, 0, 0, 0, 0, 0, 1.0)
	generate_layer(Sand, map_seed + 0, 2, 32, 0.4, 2.0, 0, 0.5)
	generate_layer(Grass, map_seed + 1, 8, 32, 0.5, 2.0, 0, 0.51)
	generate_layer(Rock, map_seed + 2, 4, 16, 0.45, 2.0, 10.0, 0.41, true)
	Log.line("Layer generated", self, Log.LEVEL.INFO, [OS.get_ticks_msec() - time])
	time = OS.get_ticks_msec()
	generate_nature()
	Log.line("Nature generated", self, Log.LEVEL.INFO, [OS.get_ticks_msec() - time])
	time = OS.get_ticks_msec()
	spawnpoints = PoolVector2Array()
	make_spawnpoints(players)
	generate_oregano()
	Log.line("Spawnpoints and Oregano generated", self, Log.LEVEL.INFO, [OS.get_ticks_msec() - time])
	if not Engine.editor_hint:
		time = OS.get_ticks_msec()
		generate_pathfinding()
		Log.line("Pathfinding generated", self, Log.LEVEL.INFO, [OS.get_ticks_msec() - time])
	time = OS.get_ticks_msec()
	make_minimap()
	Log.line("Minimap generated", self, Log.LEVEL.INFO, [OS.get_ticks_msec() - time])


#-[SIGNAL METHODS]--------------------------------------------------------------
