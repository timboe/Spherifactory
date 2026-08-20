extends Node

# Constants
const M_SOL := 150
const INSERTER_RADIUS_MOD = 0.2
const MAX_STORAGE := 49
const MAX_INPUT_LANES := 6
const MAX_RINGS := 11
const MAX_LANES := 4
const SAVE_FORMAT_VERSION = 2
const CAMPAIGN_FORMAT_VERSION = 1
const MAX_TRANSMUTE = 3
const GEM_SIZE = 4

const GAME_SAVE_FILE := "user://save_data.json"
const SETTINGS_SAVE_FILE := "user://settings.json"
const CAMPAIGN_SAVE_FILE := "user://campaign_data.json"
const CAMPAIGN_INITIAL_FILE := "res://resources/campaign_data.json"

enum {BUILDING_UNSET, BUILDING_EXTRACTOR, BUILDING_INSERTER, BUILDING_FACTORY}
enum {OUTWARDS, INWARDS}

#####################################################
# Helper globals (transient)
var last_pressed = null
var last_satelite_type = null
var last_satelite_recipe = null

#####################################################
# Helper - save / load game
var request_load = null
var snap # screenshot data

#####################################################
# Current level & configuration globals
var campaign = null
# Unpacked into vars...
var data = null
var recipies = null
var mission = null
var factories_pull_from_above : bool = true

#####################################################
# Current game data to persist
var sandbox = false
var sandbox_injectors = []
var rings : int = 12 # Only need to persist in sandbox mode
var lanes : int = 4 # Only need to persist in sandbox mode
#
var level : int = 1
var remaining : int = 1000
var to_subtract : int = 0 # Used to animate remaining
var game_finished : bool = false
var exported = {} # Statistics
var time_played : float = 0
var tutorial_message = 0

#####################################################
# Helper functions
func lighten(var c : Color) -> Color:
	return Color.from_hsv(c.h, 
		c.s - (c.s * 0.75),  # Lighten
		c.v)

#####################################################
# Scene changing 
var current_scene = null

func _ready():
	# Seed the global RNG so randi() (hint scramble, etc.) differs per run
	randomize()

func populate_data():
	recipies = campaign["recipies"]
	data = campaign["resources"]
	for r in data:
		data[r]["color"] = Color(data[r]["color_hex"])
			
func set_basics():
	recipies = {}
	data = {}
	var none = {}
	none["color_hex"] = "ff000000"
	none["mode"] = ""
	none["shape"] = 0
	none["special"] = true
	var sol = {}
	sol["color_hex"] = "ff000000"
	sol["mode"] = ""
	sol["shape"] = 0
	sol["special"] = true
	var H = {}
	H["color_hex"] = "ffda1717"
	H["mode"] = "+"
	H["shape"] = 0
	H["special"] = false
	Global.data["None"] = none
	Global.data["Sol"] = sol
	Global.data["H"] = H
	for r in data:
		data[r]["color"] = Color(data[r]["color_hex"])
			
func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	# This runs deferred (idle time, not inside a signal callback), so an
	# immediate free() is safe here. Using free() rather than queue_free()
	# avoids a one-frame overlap where both scenes exist in the tree, which
	# would make root-wide find_node() calls in the new scene resolve to
	# nodes of the old (dying) scene.
	var old_scene = get_tree().get_current_scene()
	if old_scene != null:
		old_scene.free()
	print("change to ", path)
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene(current_scene)

#####################################################
# Cache of all campaign data
var campaigns := {}
var saves := {}
var settings := {}
