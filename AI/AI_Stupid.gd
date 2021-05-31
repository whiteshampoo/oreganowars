
# +------------------------------------------------------+
# |                                                      |
# | Written by Benedikt Wicklein aka whiteshampoo - 2021 | 
# |                                                      |
# |               License: CC BY-NC-SA 4.0               |
# |  https://creativecommons.org/licenses/by-nc-sa/4.0/  |
# |                                                      |
# +------------------------------------------------------+


extends Node2D
class_name StupidAI

#-[CONSTANTS]---------------------------------------------------------------------

const ATTACK_THRESHOLD : int = 10
const ATTACK_THRESHOLD_MOD : int = 2
const ATTACK_SIZE : int = 5
const ATTACK_SIZE_MOD : int = 2
const RETREAT_SIZE : int = 1
const WANTED_BUILDINGS : Array = [
	"Oregano Refinery",
	"Small Factory",
	"Big Factory",
	"Oregano Refinery",
	"MG Tower Tier 1",
	"Rocket Tower Tier 1",
	"Cannon Tower Tier 1",
	"Small Factory",
	"Big Factory",
	"Oregano Refinery",
	"MG Tower Tier 2",
	"Rocket Tower Tier 2",
	"Cannon Tower Tier 2",
	"Oregano Refinery",
	"MG Tower Tier 2",
	"Rocket Tower Tier 2",
	"Cannon Tower Tier 2",
	"Small Factory",
	"Big Factory"
]

#-[SIGNALS]---------------------------------------------------------------------



#-[EXPORT]----------------------------------------------------------------------

export (String, "null", "red", "blue", "green", "yellow") var faction : String = "null"


#-[ONREADY]---------------------------------------------------------------------

onready var T : Timer = $Timer

#-[VAR]-------------------------------------------------------------------------

var units : Array = Array()
var buildings : Array = Array()
var enemies : Array = Array()

var attacker : Array = Array()
var attack_target : Node2D = null
var next_attack_threshold : int = ATTACK_THRESHOLD + randi() % ATTACK_THRESHOLD_MOD

var known_units : Array = Array()
var waiting : int = int(rand_range(0, 10))

var next_building : String = ""
var saving_money : int = 0

var attacks : int = 0


#-[SETGET METHODS]--------------------------------------------------------------



#-[BUILTIN GODOT METHODS]-------------------------------------------------------

func _ready() -> void:
	assert(faction != "null")
	get_all_units_from_map()
	known_units = units.duplicate()


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

func get_all_units_from_map() -> void:
	units.clear()
	buildings.clear()
	enemies.clear()
	for unit in get_parent().get_children():
		if not unit.is_in_group("Unit") and not unit.is_in_group("Building"): continue
		if unit.faction == faction:
			if unit.is_in_group("Unit"):
				units.append(unit)
			if unit.is_in_group("Building"):
				buildings.append(unit)
		else:
			enemies.append(unit)

func find_target() -> Node2D:
	return enemies[randi() % enemies.size()] if enemies else null

func find_location_and_build(building : Building) -> void:
	var start_angle : float = (randi() % 16) * 22.5
	var radi : Array = range(2, 5)
	radi.invert()
	buildings.shuffle()
	for radius in radi:
		for b in buildings:
			for angle in range(0, 360 - 22.5, 22.5):
				building.position = b.position + Vector2.RIGHT.rotated(deg2rad(start_angle + angle)) * radius * 64
				building.align_position()
				if building.check_map_points() and building.check_path_points():
					building.build()
					if building.built:
						return
					else:
						Log.line("Cannot place building", self, Log.LEVEL.ERROR, [building])
						building.queue_free()
						return
#				else:
#					var polygon : Polygon2D = Polygon2D.new()
#					var points : PoolVector2Array = PoolVector2Array()
#					points.append(Vector2(0, 0))
#					points.append(Vector2(128, 0))
#					points.append(Vector2(128, 128))
#					points.append(Vector2(0, 128))
#					polygon.polygon = points
#					polygon.color = Color(1.0, 0.0, 0.0, 0.2)
#					polygon.position = building.position
#					get_parent().add_child(polygon)
	Log.line("Cannot find a free spot to build", self, Log.LEVEL.ERROR, [building])
	building.queue_free()


func clear_dead_units(a : Array) -> void:
	for i in a.duplicate():
		if not is_instance_valid(i) or i.is_queued_for_deletion():
			Log.line("Remove dead unit", self, Log.LEVEL.DEBUG, [i])
			a.erase(i)

func clear_all_dead_units() -> void:
	clear_dead_units(units)
	clear_dead_units(buildings)
	clear_dead_units(enemies)

	clear_dead_units(attacker)
	if not is_instance_valid(attack_target):
		if attack_target != null:
			attack_target = find_target()
		attack_target = null

	clear_dead_units(known_units)

func check_next_building() -> void:
	var b : Array = buildings.duplicate()
	var r : String = ""
	for wanted in WANTED_BUILDINGS:
		r = wanted
		for i in b.size():
			match wanted:
				"Oregano Refinery":
					if b[i] is OreganoRefinery:
						b.remove(i)
						r =  ""
						break
				"Small Factory":
					if b[i] is SmallFactory:
						b.remove(i)
						r =  ""
						break
				"Big Factory":
					if b[i] is BigFactory:
						b.remove(i)
						r = ""
						break
				"Wall":
					if b[i] is Wall:
						b.remove(i)
						r = ""
						break
				"Oregano Refinery":
					if b[i] is OreganoRefinery:
						b.remove(i)
						r =  ""
						break
				"MG Tower Tier 1":
					if b[i] is MGTowerTier1:
						b.remove(i)
						r = ""
						break
				"MG Tower Tier 2":
					if b[i] is MGTowerTier2:
						b.remove(i)
						r = ""
						break
				"Cannon Tower Tier 1":
					if b[i] is CannonTowerTier1:
						b.remove(i)
						r = ""
						break
				"Cannon Tower Tier 2":
					if b[i] is CannonTowerTier2:
						b.remove(i)
						r = ""
						break
				"Rocket Tower Tier 1":
					if b[i] is RocketTowerTier1:
						b.remove(i)
						r = ""
						break
				"Rocket Tower Tier 2":
					if b[i] is RocketTowerTier2:
						b.remove(i)
						r = ""
						break
				_:
					assert(false, "building not recognized")
		if r:
			next_building = r
			return

		
func logic() -> void:
	Log.line("Start AI Logic", self, Log.LEVEL.DEBUG, [faction])
		
	clear_all_dead_units()
	var hq : HeadQuarter = null
	var refineries : Array = Array()
	var small_factory : Array = Array()
	var big_factory : Array = Array()
	var under_attack : bool = false
	var harvester : Array = Array()
	if not buildings:
		for unit in units:
			unit.set_state(Unit.STATE.SEARCH_AND_DESTROY)
		Log.line("AI defeated", self, Log.LEVEL.INFO, [faction])
		queue_free()
	for b in buildings:
		#if not b.built
		if b.under_attack:
			under_attack = true
			if b is HeadQuarter:
				attacker.clear()
				attack_target = null
			for u in units:
				if not u in attacker:
					u.set_target_enemy(b.under_attack)
		if b is SmallFactory: small_factory.append(b)
		if b is BigFactory: big_factory.append(b)
		if b is HeadQuarter: hq = b
		if b is OreganoRefinery: refineries.append(b)
		if b.hitpoints < b.hitpoints_max * 0.5:
			b.Repair(0)
	
	if hq:
		if buildings.size() < WANTED_BUILDINGS.size() + 1:
			check_next_building()
			Log.line("Want building", self, Log.LEVEL.DEBUG, [next_building])
		else:
			next_building = ""
			
			
	for u in units.duplicate():
		if not u in known_units.duplicate():
			known_units.append(u)
			if not u is Harvester:
				u.set_target(buildings[randi() % buildings.size()].position + Vector2((randf() - 0.5) * 8, (randf() - 0.5) * 8) * 64)
		if u.under_attack and not u in attacker and not u.path:
			for u2 in units:
				if not u2.under_attack or u2.target_enemy:
					u2.set_target_enemy(u.under_attack)
		if u is Harvester:
			units.erase(u)
			harvester.append(u)
				
	if not is_instance_valid(attack_target):
		Log.line("Search next target", self, Log.LEVEL.DEBUG)
		for a in attacker:
			if is_instance_valid(a.under_attack):
				attack_target = a.under_attack
				Log.line("Use attacking enemy as target", self, Log.LEVEL.DEBUG, [attack_target])
				break
		if not attack_target:
			attack_target = find_target()
			Log.line("New target found", self, Log.LEVEL.DEBUG, [attack_target])
			
		for a in attacker.duplicate():
			if not is_instance_valid(a):
				attacker.erase(a)
				continue
			a.set_target_enemy(attack_target, attacker)
	
	if attacker and attacker.size() <= RETREAT_SIZE:
		Log.line("Retreat", self, Log.LEVEL.DEBUG)
		for a in attacker.duplicate():
			if not is_instance_valid(a):
				attacker.erase(a)
				continue
			a.set_state(Unit.STATE.RETREAT)
		attacker.clear()
		attack_target = null
		#waiting /= 2
	
	for u in attacker:
		units.erase(u)
		
	if units.size() >= next_attack_threshold and not under_attack:
		Log.line("Create attack", self, Log.LEVEL.DEBUG, [attack_target])
		next_attack_threshold = ATTACK_THRESHOLD + attacks + int(rand_range(-ATTACK_THRESHOLD - attacks / 4, ATTACK_THRESHOLD + attacks / 4 + 1))
		var attack_with : int = ATTACK_SIZE + attacks / 4 + int(rand_range(-ATTACK_SIZE_MOD - attacks / 4, ATTACK_SIZE_MOD + attacks / 4 + 1))
		Log.line("Available units", self, Log.LEVEL.DEBUG, [units.size()])
		Log.line("Attack-size", self, Log.LEVEL.DEBUG, [attack_with])
		if units.size() > attack_with:
			units.shuffle()
			for i in attack_with:
				attacker.append(units[i])
				if is_instance_valid(attack_target):
					units[i].set_target_enemy(attack_target, attacker)
			waiting = int((6 + randf() * 150 - attacks) / T.wait_time)
			attacks = min(attacks + 1, 20)
		else:
			Log.line("Cannot attack", self, Log.LEVEL.DEBUG)

	for u in attacker:
		if u in units:
			units.erase(u)
	
	Log.line("AI Status", self, Log.LEVEL.DEBUG, [units.size(), 
												attacker.size(), 
												next_attack_threshold, 
												waiting, 
												saving_money,
												Global.faction_credits[faction]])

	if waiting > 0:
		waiting -= 1
		return
	
	if saving_money >= Global.faction_credits[faction]:
		Log.line("saving money", self, Log.LEVEL.DEBUG)
		return
	else:
		saving_money = 0
	
	if hq:
		if next_building:
			var num : int = Array(hq.buttons_text).find(next_building)
			assert(num != -1, "building not found")
			if hq.progress >= 100.0 and hq.build_finished:
				Log.line("Building finished", self, Log.LEVEL.DEBUG)
				var new_building : Building = hq.Build_Building(num)
				if is_instance_valid(new_building): 
					find_location_and_build(new_building)
				else:
					Log.line("Building vanished", self, Log.LEVEL.ERROR)
			elif not hq.work:
				if hq.tech < hq.buttons_tech[num]:
					Log.line("HQ Tech-upgrade", self, Log.LEVEL.DEBUG)
					hq.Tech_Update(hq.tech + 2)
				else:
					Log.line("Start building", self, Log.LEVEL.DEBUG, [hq.buttons_text[num]])
# warning-ignore:return_value_discarded
					hq.Build_Building(num)
	if refineries.size() > 0 or not hq or true:
		if harvester.size() < buildings.size() / 3 + 1:
			for b in refineries:
				if b.work != "": continue
				Log.line("Start building", self, Log.LEVEL.DEBUG, [b, b.buttons_text[4]])
				b.Build_Unit(4)

		for b in small_factory:
			if b.work != "": continue
			if attacker and Global.faction_credits[faction] > 1000 and b.tech == 0:
				Log.line("Tech-update for Small Factory", self, Log.LEVEL.DEBUG, [b])
				b.Tech_Update(b.tech + 2)
			if units.size() < ATTACK_THRESHOLD + ATTACK_THRESHOLD_MOD + 1 + attacks:
				var u : int = 4 + randi() % 6
				Log.line("Start building", self, Log.LEVEL.DEBUG, [b, b.buttons_text[u]])
				b.Build_Unit(u)

		for b in big_factory:
			if b.work != "": continue
			if attacker and Global.faction_credits[faction] > 3000 and b.tech == 0:
				Log.line("Tech-update for Big Factory", self, Log.LEVEL.DEBUG, [b])
				b.Tech_Update(b.tech + 2)
			if units.size() >= (ATTACK_THRESHOLD + attacks) and Global.faction_credits[faction] > 2000 :
				var u : int = 4 + randi() % 2
				Log.line("Start building", self, Log.LEVEL.DEBUG, [b, b.buttons_text[u]])
				b.Build_Unit(u)
	
	if refineries.size() > 0:
		if randi() % 10 == 0:
			saving_money = 500 + (randi() % 1001)
			Log.line("Start saving Money", self, Log.LEVEL.DEBUG, [saving_money, Global.faction_credits[faction]])


#-[SIGNAL METHODS]--------------------------------------------------------------


func _on_Timer_timeout():
	T.start(2.5 + rand_range(-1.0, 1.0))
	get_all_units_from_map()
	logic()
