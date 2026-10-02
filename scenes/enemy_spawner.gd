extends Node3D

@onready var enemies_parentnode = $"../Enemies"

var enemy_infantery_scene = preload("res://scenes/enemies/infantery.tscn")
var enemy_tank_scene = preload("res://scenes/enemies/tank.tscn")
var enemy_vtb_scene = preload("res://scenes/enemies/vtb.tscn")

var is_win = false

# Character Key:
# 'i' = Infantry (Standard)
# 't' = Tank (Slow, High HP)
# 'v' = VTB (Fast, High HP)
# ' ' = Wait (Delay)

var rounds: Array[String] = [
#	"v",
#	"iiiiiiii    tttttttt    vvvvvvvvvvvvvvvvvvvvv",
#	"tttttvvvvvvvvvvvvvvvvvvvvv",
#	"i v t",
	# --- PHASE 1: RECRUITMENT (Rounds 1-5) ---
	"i   i   i   i   i",                  # Round 1: Intro (50 Total HP)
	"i i i i i i",                         # Round 2: Tighter spacing
	"i i i   i i i   i i i",               # Round 3: Squads
	"i i i i iiiiii",                 # Round 4: Constant stream (100 HP)
	"i i i   t   i i i",                   # Round 5: First Tank (50 HP sponge) - Space needed for infantry behind

	# --- PHASE 2: ARMOR (Rounds 6-10) ---
	"t   t   t",                           # Round 6: Tank Squad (150 HP)
	"i i i i   t   i i i i tt",               # Round 7: Tank protecting rear guard
	"t   ii t   iiiiii   tt",               # Round 8: Mixed Slow/Fast
	"t   t   t   t   t",                   # Round 9: Heavy Armor Column
	"i i i   v   i i i",                   # Round 10: First VTB (120 HP Boss!) - Big difficulty spike

	# --- PHASE 3: ESCALATION (Rounds 11-15) ---
	"v             v",                           # Round 11: VTB Squad (360 HP)
	"t i t i t i t i t i",                 # Round 17: Slow/Fast alternate (Spacing critical)
	"t   t   v   t   t",                   # Round 12: VTB protected by Tanks
	"t t t t t t t",             # Round 13: Mass Swarm (Speed check)
	"v   i i i   v   iiiiiiii",               # Round 14: VTBs leading infantry charges
	"t   t   t   v   vv",                   # Round 15: Heavy mix

	# --- PHASE 4: THE GRIND (Rounds 16-20) ---
	"v  v  v",                           # Round 16: VTB Rush (600 HP)
	"v   v   v   t   t   t",               # Round 18: Fast vanguard, Slow rearguard
	"t   t   t   t   t   t   t",           # Round 19: Tank Wall
	"v i v i v i v i v i",                 # Round 20: High Damage Speed Wave

	# --- PHASE 5: ELITE WAVES (Rounds 21-25) ---
	"t   v   t   v   t   v",               # Round 21: Heavy Alternating
	"v v v   v v v",                       # Round 22: VTB Clusters
	"t t t   vvvv   t t t",                 # Round 23: Armored Sandwich
	"v v v v v v v v",                     # Round 24: 8 VTBs (960 HP)
	
	# --- PHASE 6: TOTAL CHAOS (Rounds 26-30) ---
	"t t t t   v v v v",                   # Round 26: The Wall & The Breakers
	"v i t   v i t   v i t",               # Round 27: Combined Arms
	"v v v v v v v v v v",                 # Round 28: 10 VTBs (1200 HP)
	"t   v   v   v   v   v   t",           # Round 29: VTB rush protected by Tanks
	"v v v v v v v v v v v v v v v",        # Round 30: THE END (15 VTBs = 1800 HP)
	"iiiiiiii    tttttttt    vvvvvvvvvvvvvvvvvvvvv"
]

# Settings
var tick_time: float = 0.8  # Seconds per character in the string
var break_time: float = 20.0

# State Variables
var current_round: int = 0
var is_in_break: bool = true
var break_timer: float = 0.0
var wave_timer: float = 0.0
var wave_string_index: int = 0
var current_wave_string: String = ""


var map_changing = false
var trust_fall_timer: float = 0.0
func _on_map_changed(_map_rid):
	print("Map changed")
	#print(_map_rid)
	# Trust momentum for 0.1s (approx 6 physics frames)
	# This bridges the gap while the NavMesh is rebuilding
	trust_fall_timer = 0.2 * Engine.time_scale # we also need this for safety
	map_changing = not map_changing # it looks like every change is 2 emissions

func _ready() -> void:
	NavigationServer3D.map_changed.connect(_on_map_changed)
	# Initialize the first break
	start_break()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _physics_process(delta: float) -> void:
	
	if trust_fall_timer > 0:
		trust_fall_timer -= delta
	else:
		map_changing = false
	
	#if map_changing:
	#	print("Changing")
	#else:
	#	print("nochange")
	
	if Input.is_action_just_pressed("ui_focus_next"):
		Engine.time_scale = 4.0#0.25
	if Input.is_action_just_released("ui_focus_next"):
		Engine.time_scale = 1.0
	
	if current_round >= rounds.size() and get_tree().get_nodes_in_group("enemies").is_empty():
		print("All rounds completed! You win!")
		is_win = true
		set_physics_process(false)
		
	if is_in_break:
		_process_break(delta)
	else:
		_process_wave(delta)

func _process_break(delta: float) -> void:
	break_timer -= delta
	
	# Allow player to skip break by pressing Space (ui_accept)
	# logic: if the user explicitly pressed space, or is holding space and the previous turn is fully over
	if Input.is_action_just_pressed("ui_accept"):
		break_timer = 0.0
	if Input.is_action_pressed("ui_accept") and get_tree().get_nodes_in_group("enemies").is_empty():
		break_timer = 0.0
		
	if break_timer <= 0:
		start_next_round()

func _process_wave(delta: float) -> void:
	wave_timer -= delta
	
	if wave_timer <= 0:
		spawn_next_step()
		wave_timer += tick_time # Reset timer for the next "tick"

func start_break():
	is_in_break = true
	break_timer = break_time
	print("--- Break Started --- Press SPACE to skip. Next Round: ", current_round + 1)

func start_next_round():
	if current_round >= rounds.size():
		print("No more waves, waiting for enemies to perish.")
		return
		
	is_in_break = false
	current_wave_string = rounds[current_round]
	wave_string_index = 0
	wave_timer = 0.0 # Start spawning immediately
	
	print(">>> Round ", current_round + 1, " Started! Pattern: ", current_wave_string)

func spawn_next_step():
	# Check if we finished the string
	if wave_string_index >= current_wave_string.length():
		current_round += 1
		start_break()
		return
		
	var char_code = current_wave_string[wave_string_index]
	wave_string_index += 1
	
	match char_code:
		"i": spawn_unit(enemy_infantery_scene)
		"t": spawn_unit(enemy_tank_scene)
		"v": spawn_unit(enemy_vtb_scene)
		" ": pass # Space means wait one tick
		_: pass   # Unknown characters are treated as delays

func spawn_unit(scene: PackedScene):
	var enemy = scene.instantiate()
	enemies_parentnode.add_child(enemy)
	enemy.global_position = global_position
	
	# Ensure enemy is in the group so Towers can see it
	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")
