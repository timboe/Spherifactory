extends Button

const test_save := "res://test_save.json"
var dict : Dictionary

func new_game_common():
	var name = get_parent().get_parent().get_node("CampaignName").text
	dict = Global.campaigns[name].duplicate(true)
	Global.level = 0
	Global.sandbox_injectors = []
	Global.request_load = null
	Global.tutorial_message = 0
	# Reset persistent state from any previous session
	Global.exported = {}
	Global.game_finished = false
	Global.remaining = 0
	Global.to_subtract = 0
	Global.time_played = 0
	Global.sandbox = false

func _on_Play_pressed():
	new_game_common()
	Global.campaign = dict
	Global.level = 0
	# Rings, lanes, factories_pull_from_above - will be read from campaign missions data
	Global.sandbox = false
	Global.goto_scene("res://scenes/ShieldGen.tscn")

func _on_Sandbox_pressed():
	new_game_common()
	dict["missions"] = [] # Delete mission data, we don't need it
	Global.campaign = dict
	Global.rings = Global.MAX_RINGS
	Global.lanes = Global.MAX_LANES
	Global.factories_pull_from_above = true
	Global.sandbox = true
	Global.goto_scene("res://scenes/ShieldGen.tscn")

func _on_Level_pressed():
	new_game_common()
	Global.campaign = dict
	Global.level = int(text)-1
	print("Starting from level " , Global.level)
	# Rings, lanes, factories_pull_from_above - will be read from campaign missions data
	Global.sandbox = false
	Global.goto_scene("res://scenes/ShieldGen.tscn")
