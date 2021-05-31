
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

enum MENU_STATE {
	NONE,
	UNIT,
	BUILDING,
	MENU
}

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var Minimap : TextureRect = $Splitter/Sidebar/UnitControl2/Minimap
onready var MinimapOregano : TextureRect = $Splitter/Sidebar/UnitControl2/MinimapOregano
onready var MinimapOverlay : TextureRect = $Splitter/Sidebar/UnitControl2/FogOfWarOverlay
onready var FogOfWarOverlay : TextureRect = $Splitter/Sidebar/UnitControl2/DarknessOverlay
onready var DarknessOverlay : TextureRect = $Splitter/Sidebar/UnitControl2/MinimapOverlay
onready var Level : Node2D = $Splitter/Game/Viewport/LevelTemplate
onready var ButtonContainer : VBoxContainer = $Splitter/Sidebar/UnitControl/Container
onready var MenuContainer : VBoxContainer = $Splitter/Sidebar/UnitControl/Menu
onready var Credits : Label = $Splitter/Sidebar/CreditsBG/Credits
onready var Status : Label = $Status

onready var Exit : Button = $Splitter/Sidebar/UnitControl/Menu/Exit
onready var Save : Button = $Splitter/Sidebar/UnitControl/Menu/Save
onready var Music : CheckBox = $Splitter/Sidebar/UnitControl/Menu/Music
onready var Sound : CheckBox = $Splitter/Sidebar/UnitControl/Menu/Sound

#-[VAR]-------------------------------------------------------------------------

var menu_state : int = 0
var update_button : Button = null
var update_button_text : String = ""
var status : String = "playing"

#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	Log.move_to_bottom()
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(960, 512), 1)
	Minimap.texture.image = Level.Map.minimap
	Level.SelectionBox.connect("unit_selected", self, "unit_selected")
	Level.SelectionBox.connect("building_selected", self, "building_selected")
	Level.SelectionBox.connect("deselect", self, "container_clear")

	Sound.pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Sound"))
	Music.pressed = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))



func _process(_delta : float) -> void:
	match status:
		"win":
			Status.text = "Victory"
			Status.visible = true
		"defeat":
			Status.text = "Defeat"
			Status.visible = true
	
	MinimapOregano.texture.image = Level.Map.minimap_oregano
	MinimapOverlay.texture.image = Level.minimap_overlay
	FogOfWarOverlay.texture.image = Level.fog_of_war_overlay
	DarknessOverlay.texture.image = Level.darkness_overlay
	Credits.text = "Oregano: " + str(int(Global.faction_credits[Global.player_faction]))
	match menu_state:
		MENU_STATE.UNIT:
			if not Global.selected_units:
				container_clear()
		MENU_STATE.BUILDING:
			if not is_instance_valid(Global.selected_building):
				container_clear()
				return
			if Global.selected_building.button_update:
				Global.selected_building.button_update = false
				building_selected()
			if is_instance_valid(update_button):
				update_button.text = update_button_text + " " + str(int(Global.selected_building.progress)) + "%" 
				


func _physics_process(_delta : float) -> void:
	pass


func _input(event : InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused
		if get_tree().paused:
			Level.modulate = Color.darkgray
			ButtonContainer.visible = false
			MenuContainer.visible = true
		else:
			Level.modulate = Color.white
			ButtonContainer.visible = true
			MenuContainer.visible = false
	$Splitter/Game/Viewport.unhandled_input(event)
	if event is InputEventMouseButton:
		if event.position.x < Level.get_viewport_rect().end.x: return
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					if event.position.y < Minimap.rect_size.y:
						Level.Cam.position = minimap_to_map_coords(event.position)
						Level.Cam.recalc_and_interpolate(true)
				BUTTON_RIGHT:
					if event.position.y < Minimap.rect_size.y:
						for unit in Global.selected_units:
							unit.set_target(minimap_to_map_coords(event.position), false, Global.selected_units)


func _unhandled_input(_event : InputEvent) -> void:
	pass


func _unhandled_key_input(_event : InputEventKey) -> void:
	pass


func _draw() -> void:
	pass

#-[INHERITED METHODS]-----------------------------------------------------------



#-[OWN METHODS]-----------------------------------------------------------------

func container_clear() -> void:
	update_button = null
	menu_state = MENU_STATE.NONE
	for child in ButtonContainer.get_children():
		ButtonContainer.remove_child(child)
		child.queue_free()

func add_button(text : String, method : String, value : int, enabled : bool = true) -> Button:
	var button : Button = Button.new()
	ButtonContainer.add_child(button)
	
	button.text = text
	button.rect_min_size = Vector2(0, 28)
	if not enabled: 
		button.disabled = true
	for unit in Global.selected_units:
# warning-ignore:return_value_discarded
		button.connect("pressed", unit, method, [value])
	if is_instance_valid(Global.selected_building):
# warning-ignore:return_value_discarded
		button.connect("pressed", Global.selected_building, method, [value])
	return button

func unit_selected() -> void:
	container_clear()
	menu_state = MENU_STATE.UNIT
# warning-ignore:return_value_discarded
	add_button("STOP", "set_state", Unit.STATE.STOP)
# warning-ignore:return_value_discarded
	add_button("GUARD", "set_state", Unit.STATE.GUARD) 
# warning-ignore:return_value_discarded
	add_button("PATROL", "set_state", Unit.STATE.PATROL) 
# warning-ignore:return_value_discarded
	add_button("CHASE", "set_state", Unit.STATE.CHASE) 
# warning-ignore:return_value_discarded
	add_button("FLEE", "set_state", Unit.STATE.FLEE) 
# warning-ignore:return_value_discarded
	add_button("SCOUT", "set_state", Unit.STATE.SCOUT) 
# warning-ignore:return_value_discarded
	add_button("RETREAT", "set_state", Unit.STATE.RETREAT) 
# warning-ignore:return_value_discarded
	add_button("SEARCH AND DESTROY", "set_state", Unit.STATE.SEARCH_AND_DESTROY)


func building_selected() -> void:
	container_clear()
	menu_state = MENU_STATE.BUILDING
	for i in Global.selected_building.buttons_text.size():
		if Global.selected_building.buttons_tech[i] > Global.selected_building.tech: continue
		
		var text : String = Global.selected_building.buttons_text[i]
		var label : String = text
		
		var price : int = Global.selected_building.buttons_price[i]
		if price:
			label += " (" + str(price) + ")"
				
		var method : String = text.replace(" ", "_")
		var enabled : bool = price <= Global.faction_credits[Global.player_faction]
		
		var work = Global.selected_building.work
		if work != "":
			if work == text:
				update_button_text = label
				label += " " + str(int(Global.selected_building.progress)) + "%"
				enabled = true
			else:
				enabled = false
		var btn : Button = add_button(label, method, i, enabled)
		if "%" in label:
			update_button = btn

func minimap_to_map_coords(pos : Vector2) -> Vector2:
	pos.x -= Level.get_viewport_rect().end.x
	pos.x *= Level.Map.width / 256.0
	pos.y *= Level.Map.height / 256.0
	pos *= 64
	return pos

#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_Exit_pressed():
	get_tree().paused = false
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Menu/Main.tscn")


func _on_Save_pressed():
	pass
#	var save : File = File.new()
#	save.open("user://map.txt", File.WRITE)
#	save.store_var(inst2dict(self), true)
#	save.close()
#	save.open("user://global.txt", File.WRITE)
#	save.store_var(inst2dict(get_tree().get_root().get_node("Global")), true)
#	save.close()


func _on_Music_toggled(mute : bool):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not mute)


func _on_Sound_toggled(mute : bool):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), not mute)


func _on_TestStatus_timeout():
	if not get_tree().get_nodes_in_group("StupidAI"): 
		status = "win"
		return
	status = "defeat"
	for node in get_tree().get_nodes_in_group("Unit"):
		if node.faction == "blue":
			status = "playing"
			return
	for node in get_tree().get_nodes_in_group("Building"):
		if node.faction == "blue":
			status = "playing"
			return
	
