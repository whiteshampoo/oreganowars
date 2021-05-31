
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Control

#-[CONSTANTS]---------------------------------------------------------------------



#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var sound : CheckBox = $Container/VolumeOptions/Sound
onready var music : CheckBox = $Container/VolumeOptions/Music

onready var map_size : SpinBox = $Container/SkirmishOptions/MapSize
onready var enemies : SpinBox = $Container/SkirmishOptions/Enemies
onready var darkness : CheckBox = $Container/SkirmishOptions/Darkness
onready var fog_of_war : CheckBox = $Container/SkirmishOptions/FogOfWar
onready var itch : Button = $Container/Itch
onready var exit : Button = $Container/Exit

#-[VAR]-------------------------------------------------------------------------



#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	randomize()
	var s : int = randi()
	seed(s)
	Log.move_to_bottom()
	Log.line("Menu ready", self, Log.LEVEL.INFO, [s])

	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(960, 512), 1)
	$MapGenerator.generate_map(64, 36, 0, randi())
	sound.pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Sound"))
	music.pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	
	Global.new_game_map_size = int(map_size.value)
	Global.new_game_enemies = int(enemies.value)
	Global.new_game_darkness = darkness.pressed 
	Global.new_game_fog_of_war = fog_of_war.pressed
	
	if OS.get_name() == "HTML5":
		Log.line("HTML5 detected", self, Log.LEVEL.INFO)
		itch.visible = false
		exit.visible = false
	
	if not Global.music_player.playing:
		Global.play_music()
		
	Global.delete_2D_sounds()


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



#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_Campaign_pressed():
	Log.line("Campaign", self, Log.LEVEL.INFO)
	pass # Replace with function body.
	
	
func _on_Skirmish_pressed():
	Log.line("Skirmish", self, Log.LEVEL.INFO, [Global.new_game_map_size, 
												Global.new_game_enemies,
												Global.new_game_darkness,
												Global.new_game_fog_of_war])
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://InGame.tscn")


func _on_MapSize_value_changed(value : int):
	Log.line("Mapsize changed", self, Log.LEVEL.INFO, [value])
	Global.new_game_map_size = value


func _on_Enemies_value_changed(value : int):
	Log.line("Enemies changed", self, Log.LEVEL.INFO, [value])
	Global.new_game_enemies = value


func _on_Darkness_toggled(button_pressed : bool):
	Log.line("Darkness toggled", self, Log.LEVEL.INFO, [button_pressed])
	Global.new_game_darkness = button_pressed 


func _on_FogOfWar_toggled(button_pressed : bool):
	Log.line("FOW toggled", self, Log.LEVEL.INFO, [button_pressed])
	Global.new_game_fog_of_war = button_pressed


func _on_Music_toggled(mute : bool):
	Log.line("Music toggled", self, Log.LEVEL.INFO, [mute])
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not mute)


func _on_Sound_toggled(mute : bool):
	Log.line("Sound toggled", self, Log.LEVEL.INFO, [mute])
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), not mute)


func _on_HowToPlay_pressed():
	Log.line("HowToPlay-button pressed", self, Log.LEVEL.INFO)
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Menu/Help.tscn")


func _on_Itch_pressed():
	Log.line("Itch-button pressed", self, Log.LEVEL.INFO)
# warning-ignore:return_value_discarded
	OS.shell_open("https://whiteshampoo.itch.io/oregano-wars")


func _on_Godot_Wild_Jam_pressed():
	Log.line("Jam-button pressed", self, Log.LEVEL.INFO)
# warning-ignore:return_value_discarded
	OS.shell_open("https://itch.io/jam/godot-wild-jam-31")


func _on_Godot_Engine_pressed():
	Log.line("Godot-button pressed", self, Log.LEVEL.INFO)
# warning-ignore:return_value_discarded
	OS.shell_open("https://godotengine.org")
	

func _on_Exit_pressed():
	Log.line("Exit-button pressed", self, Log.LEVEL.INFO)
	Log.show_dialog(true)
	exit.text = "Please wait..."
	disable_children($Container)
	#get_tree().quit()

func disable_children(node : Node) -> void:
	for n in node.get_children():
		disable_children(n)
	if node.get("disabled") != null:
		node.disabled = true
	if node.get("editable") != null:
		node.editable = false

func _on_Load_pressed():
	pass
#	var file : File = File.new()
#	file.open("user://global.txt", File.READ)
#	var old_global : Node = get_tree().get_root().get_node("Global")
#	old_global.queue_free()
#	old_global.get_parent().remove_child(old_global)
#	var new_global : Node = dict2inst(file.get_var(true))
#	new_global.name = "Global"
#	get_tree().get_root().add_child(new_global)
#	file.close()
#	file.open("user://map.txt", File.READ)
#	get_tree().get_root().add_child(dict2inst(file.get_var(true)))
#	file.close()
#	queue_free()
	


func _on_Credits_pressed():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Menu/Credits.tscn")
