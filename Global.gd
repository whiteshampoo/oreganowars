
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

const SETTINGS_FILE : String = "user://settings.json"

const FACTIONS : Array = ["blue", "red", "yellow", "green"]
const FACTION_COLORS : Dictionary = {
	"red": Color("#e33c3c"),
	"blue": Color("#3c69e3"),
	"yellow": Color("#e3bb3c"),
	"green": Color("#3ce360")
}

enum SETTINGS {
	MUSIC_VOLUME,
	SOUND_VOLUME,
}

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------



#-[VAR]-------------------------------------------------------------------------

var player_faction : String= "null"
var selected_units : Array = Array()
var selected_building : Node2D = null
var placing_building : Node2D = null
var enemy_hover : Node2D = null

var faction_credits : Dictionary = {
	"red": 3000.0,
	"blue": 3000.0,
	"yellow": 3000.0,
	"green": 3000.0
}

var new_game_map_size : int = 0
var new_game_enemies : int = 0
var new_game_darkness : bool = false
var new_game_fog_of_war : bool = false

var __
var money_update : float  = 0.0

var music : Array = Array() 
var music_player : AudioStreamPlayer = null

var settings : Dictionary = Dictionary()

#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	OS.min_window_size = Vector2(960, 512)
	player_faction = "blue"
	
	settings = load_settings()
	use_settings(settings)
	
	connect("tree_exiting", self, "_exiting")
	
	music.append(preload("res://Music/Aurora.ogg"))
	music.append(preload("res://Music/Perpetual_Tension.ogg"))
	music.append(preload("res://Music/artblock.ogg"))
	music.append(preload("res://Music/laidback.ogg"))
	music.append(preload("res://Music/melon_it.ogg"))
	music.append(preload("res://Music/Wasteland_Showdown.ogg"))
	music.append(preload("res://Music/The_Odyssey.ogg"))
	music.append(preload("res://Music/Wind_Run.ogg"))
	
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
# warning-ignore:return_value_discarded
	music_player.connect("finished", self, "play_music")
	

func _process(_delta : float) -> void:
	pass
#	money_update += delta
#	if money_update >= 1.0:
#		money_update -= 1.0
#		for faction in FACTIONS:
#			update_credits(faction, 100 / 5)


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


func load_settings() -> Dictionary:
	var file : File = File.new()
	if not file.file_exists(SETTINGS_FILE):
		#Log.line("Settings-file does not exist", self, Log.LEVEL.INFO)
		return {}
	file.open(SETTINGS_FILE, File.READ)
	if not file.is_open():
		#Log.line("Settings-file cannot be opened", self, Log.LEVEL.ERROR)
		return {}
	var json : Dictionary = parse_json(file.get_as_text())
	file.close()
	if not SETTINGS.MUSIC_VOLUME in json:
		json[SETTINGS.MUSIC_VOLUME] = 1.0
	if not SETTINGS.SOUND_VOLUME in json:
		json[SETTINGS.SOUND_VOLUME] = 1.0
	print(json)
	return json


func save_settings(_settings : Dictionary) -> void:
	var file : File = File.new()
	file.open(SETTINGS_FILE, File.WRITE)
	if not file.is_open():
		#Log.line("Settings-file cannot be written", self, Log.LEVEL.ERROR)
		return
	file.store_string(JSON.print(_settings))
	file.close()
	


func use_settings(_settings : Dictionary) -> void:
	for key in _settings.keys():
		match key:
			SETTINGS.MUSIC_VOLUME:
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(_settings[key]))
			SETTINGS.SOUND_VOLUME:
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear2db(_settings[key]))

func delete_2D_sounds() -> void:
	for node in get_children():
		if node is AudioStreamPlayer2D:
			node.queue_free()

func FindTurnSide(current : float, target : float) -> int:
	if is_equal_approx(current, target):
		return 0
	var diff : float = target - current;
	if diff < 0:
		diff += 360;
	if diff > 180:
		return -1
	return 1

func get_rotation_for_tween(target_node : Node2D, target_position : Vector2) -> float:
		var rot : float = rad2deg(target_node.position.angle_to_point(target_position))
		# make sure everything is between 0 - 360 degrees
		target_node.rotation_degrees = wrapf(target_node.rotation_degrees, 0.0, 360.0)
		rot = wrapf(rot, 0.0, 360.0)
		# stuff i can't explain, but makes sense after some time at the whiteboard...
		if abs(rot - target_node.rotation_degrees) > 180.0:
			rot -= 360.0 * sign(rot - target_node.rotation_degrees)
		return rot


func calc_sound_position(pos : Vector2,
				cam_pos : Vector2,
				view_size : Vector2) -> Vector2:
	return pos - cam_pos + view_size / 2.0

func calc_sound_distance(view_size : Vector2) -> float:
	return max(view_size.x, view_size.y) * 1.5

func make_sound_2D(sound : AudioStreamOGGVorbis, 
				pos : Vector2,
				cam_pos : Vector2,
				view_size : Vector2,
				bus : String = "Master",
				db : float = 1.0) -> void:
	if sound:
		var audio_player : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		add_child(audio_player)
		audio_player.position = calc_sound_position(pos, cam_pos, view_size)
		audio_player.bus = bus
		audio_player.max_distance = calc_sound_distance(view_size)
		audio_player.attenuation = 2.0
		__ = audio_player.connect("finished", audio_player, "queue_free")
		audio_player.stream = sound
		audio_player.volume_db = db
		audio_player.play()

func update_credits(faction : String, value : int, set : bool = false) -> void:
	assert(faction in faction_credits.keys())
	if set:
		faction_credits[faction] = value
	else:
		faction_credits[faction] += value
	if is_instance_valid(selected_building):
		selected_building.button_update = true

#-[SIGNAL METHODS]--------------------------------------------------------------

func play_music() -> void:
	music_player.stream = music[randi() % music.size()]
	music_player.play()


func _exiting() -> void:
	save_settings(settings)
