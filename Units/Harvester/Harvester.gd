
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends "res://Units/Tank.gd"
class_name Harvester

#-[CONSTANTS]---------------------------------------------------------------------

enum H_STATE {
	SEARCHING,
	GATHERING,
	RETURNING,
	UNLOADING
}

const MAX_OREGANO : float = 500.0
const HARVEST_SPEED : float = 50.0
const UNLOAD_SPEED : float = 50.0

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------



#-[ONREADY]---------------------------------------------------------------------

onready var Harvesting : CPUParticles2D = $Harvesting
onready var NoRefinery : Timer = $NoRefinery
onready var Fill : Polygon2D = $Fill

#-[VAR]-------------------------------------------------------------------------

var oregano : float = 0
var last_oregano_pos : Vector2 = Vector2.ZERO
var h_state : int = H_STATE.SEARCHING
var search_step : int = 0
var refineries : Array = Array()
var unloading : bool = false
var send_tries: int = 0

#-[SETGET METHODS]--------------------------------------------------------------

func set_target(t : Vector2, auto : bool = true, _other_units : Array = []) -> void:
	Harvesting.emitting = false
	.set_target(t)
	if not auto and path:
		last_oregano_pos = path[-1]
	if not selected and not mouse_over:
		ToTarget.visible = false

func set_target_enemy(_e : Node2D, _other_units : Array = []) -> void:
	pass

#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	if not last_oregano_pos:
		last_oregano_pos = position
	state = STATE.FLEE


func _process(delta : float) -> void:
	if not NoRefinery.is_stopped(): return
	match state:
		STATE.STOP: 
			h_state = H_STATE.SEARCHING
			return
		STATE.FLEE:
			pass
		_:
			state = STATE.FLEE
			h_state = H_STATE.SEARCHING
	if h_state in [H_STATE.UNLOADING, H_STATE.GATHERING]:
		if oregano <= 0:
			Fill.visible = false
		else:
			Fill.visible = true
			var poly : PoolVector2Array = Fill.polygon
			poly[0].x = 17.0 - 25.0 * (oregano / MAX_OREGANO)
			poly[3].x = poly[0].x
			Fill.polygon = poly

	if not path:
		find_refineries()
		if oregano >= MAX_OREGANO and not h_state == H_STATE.UNLOADING:
			Log.line("Send Harvester to nearest refinery", self, Log.LEVEL.DEBUG)
			h_state = H_STATE.RETURNING
		if oregano > 0 and h_state != H_STATE.UNLOADING and h_state != H_STATE.GATHERING:
			Log.line("Try to unload Harvester", self, Log.LEVEL.DEBUG)
			for r in refineries:
				if position - r.position in r.output_points:
					h_state = H_STATE.UNLOADING
					Log.line("Unload Harvester", self, Log.LEVEL.DEBUG)
					break
		match h_state:
			H_STATE.SEARCHING:
				if not last_oregano_pos == position:
					Log.line("Send Harvester to last known Oregano-position", self, Log.LEVEL.DEBUG, [position, last_oregano_pos])
					set_target(last_oregano_pos, false)
					if not path:
						Log.line("No Path found", self, Log.LEVEL.ERROR)
						NoRefinery.start() #hack
					search_step = 0
				else:
					var s : Vector2 = spiral(search_step) * 64 + position.round()

					if s in Map.oregano_dict:
						Log.line("Found Oregano", self, Log.LEVEL.DEBUG, [search_step, s, position])
						if s in Map.blocked_tiles:
							if not self == Map.blocked_tiles[s]:
								Log.line("Oregano is blocked", self, Log.LEVEL.DEBUG)
								search_step += 1
								return
						if search_step == 0:
							last_oregano_pos = s
							h_state = H_STATE.GATHERING
							Log.line("Start Gathering", self, Log.LEVEL.DEBUG)
							Harvesting.emitting = true
							return
						else:
							send_tries += 1
							if send_tries > 3:
								Log.line("Send tries exceeded", self, Log.LEVEL.ERROR)
								send_tries = 0
								set_target(s + Vector2.ONE * rand_range(-10, 10), false)
								return
							set_target(s, false)
							search_step = 0
							return
					search_step += 1

					
			H_STATE.GATHERING:
				send_tries = 0
				position = position.round()
				if not position in Map.oregano_dict:
					h_state = H_STATE.SEARCHING
					Harvesting.emitting = false
					search_step = int(rand_range(0, 10))
					
				if not position in Map.oregano_dict:
					h_state = H_STATE.SEARCHING
					return
				var ground_oregano : float = Map.oregano_dict[position]
				var wanna_harvest : float = min(HARVEST_SPEED * delta, MAX_OREGANO - oregano)
				
				ground_oregano -= wanna_harvest
				Map.oregano_dict[position] -= wanna_harvest
				if ground_oregano <= 0:
					Map.remove_oregano(position)
#					Map.oregano_dict.erase(position)
#					var map_position : Vector2 = Map.Nature.world_to_map(position)
#					Map.Nature.set_cellv(map_position, -1)
#					Map.Nature.update_bitmask_area(map_position)
#					oregano += wanna_harvest + ground_oregano
				else:
					oregano += wanna_harvest
				if oregano >= MAX_OREGANO:
					oregano = MAX_OREGANO
					Harvesting.emitting = false
					h_state = H_STATE.RETURNING
					return
					
			H_STATE.RETURNING:
				if not refineries:
					set_state(STATE.RETREAT)
					NoRefinery.start()
					Log.line("No refinery found: retreat", self, Log.LEVEL.DEBUG)
					return
				var nearest : Building = refineries[0]
				for r in refineries:
					if position.distance_to(r.position) < position.distance_to(nearest.position):
						nearest = r
				set_target(nearest.position + nearest.output_points[randi() % nearest.output_points.size()], true)
				if not path:
					NoRefinery.start() #hack
			H_STATE.UNLOADING:
				if oregano <= 0:
					Log.line("Finished unloading", self, Log.LEVEL.DEBUG)
					unloading = false
					oregano = 0
					h_state = H_STATE.SEARCHING
					return
				
				if not unloading:
					for r in refineries:
						if position - r.position in r.output_points:
							Log.line("Start unloading", self, Log.LEVEL.DEBUG)
							unloading = true
							break
				if not unloading:
					Log.line("Refinery vanished", self, Log.LEVEL.DEBUG)
					unloading = false
					h_state = H_STATE.RETURNING
					return

				var wanna_unload : float = min(UNLOAD_SPEED * delta, oregano)
				oregano -= wanna_unload
				Global.faction_credits[faction] += wanna_unload

				
				
				
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

func find_refineries() -> void:
	refineries.clear()
	for b in get_tree().get_nodes_in_group("Building"):
		if not b.is_in_group("Building"): continue
		if not b.faction == faction: continue
		if not b.built: continue
		if b is OreganoRefinery:
			refineries.append(b)

#https://math.stackexchange.com/questions/163080/on-a-two-dimensional-grid-is-there-a-formula-i-can-use-to-spiral-coordinates-in
func spiral(n : int) -> Vector2: # I have NO idea how this works
	n += 1
# warning-ignore:narrowing_conversion
	var k : int = ceil((sqrt(n) - 1) / 2)
	var t : int = 2 * k + 1
	var m : int = t * t 
	t = t - 1
	
	if n >= m-t:
		return Vector2(k - (m - n), -k)
	else:
		m = m - t
		
	if n >= m-t:
		return Vector2(-k, -k + (m - n))
	else:
		m = m - t
		
	if n >= m-t:
		return Vector2(-k + (m - n), k)
		
	return Vector2(k, k - (m - n - t))


#-[SIGNAL METHODS]--------------------------------------------------------------
