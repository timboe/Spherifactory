extends CenterContainer

onready var campaigns = get_tree().get_root().find_node("Campaigns", true, false)
onready var new_campaign = get_tree().get_root().find_node("NewCampaignVBox", true, false)
onready var camp_editor = get_tree().get_root().find_node("CampaignEditor", true, false)
onready var load_vbox = get_tree().get_root().find_node("LoadVBox", true, false)
onready var setings = get_tree().get_root().find_node("Settings", true, false)
onready var foot_label = get_tree().get_root().find_node("FootLabel", true, false)

func _ready():
	# Load 
	Global.saves = load_from_disk(Global.GAME_SAVE_FILE)
	#
	Global.campaigns = load_from_disk(Global.CAMPAIGN_SAVE_FILE)
	if Global.campaigns.size() == 0:
		var dir = Directory.new()
		dir.copy(Global.CAMPAIGN_INITIAL_FILE, Global.CAMPAIGN_SAVE_FILE)
		Global.campaigns = load_from_disk(Global.CAMPAIGN_SAVE_FILE)
	#
	Global.settings = {}
	setings.set_default() # Ensure every key exists, then overlay saved values
	var saved_settings = load_from_disk(Global.SETTINGS_SAVE_FILE)
	for key in saved_settings:
		Global.settings[key] = saved_settings[key]
	if Global.settings["fullscreen"] != OS.window_fullscreen:
		OS.window_fullscreen = Global.settings["fullscreen"]
	print("Set fullscreen to ",Global.settings["fullscreen"])
	print("loaded with music ", Global.settings["music"])
	Music.volume_db = linear2db(Global.settings["music"] * 0.01)
	Music.start_music()
	for c in Sfx.get_children():
		if "Blip" in c.name:
			c.volume_db = linear2db(Global.settings["beeps"] * 0.01)
		else:
			c.volume_db = linear2db(Global.settings["sfx"] * 0.01)
	$MarginContainer/MarginContainer/VBoxContainer/LanguageButton.lang = Global.settings["lang"]
	TranslationServer.set_locale(Global.settings["lang"])
	show_menu("MainMenu")

func load_from_disk(var file_path) -> Dictionary:
	var file = File.new()
	if file.file_exists(file_path):
		file.open(file_path, File.READ)
		var result = JSON.parse( file.get_as_text() )
		file.close()
		if result.error == OK:
			return result.result
		else:
			print("ERROR: JSON ERROR ", result.error_string)
	return {}

func show_menu(var menu : String, var extra = null):
	for c in get_tree().get_nodes_in_group("PrimaryMenuElement"):
		c.visible = false
	get_parent().get_node(menu).visible = true
	foot_label.visible = true
	
	if self.has_method(menu):
		self.call(menu, extra)

# Extra methods

func MainMenu(var _extra):
	$MarginContainer/MarginContainer/VBoxContainer/LoadButton.disabled = (Global.saves.size() == 0)

func CampaignManager(var _extra):
	for c in campaigns.get_node("Container").get_children():
		c.queue_free()
	for camp in Global.campaigns:
		var campaign = load("res://scenes/CampaignSelector.tscn").instance()
		campaigns.get_node("Container").add_child(campaign)
		campaign.get_node("CampaignName").text = camp

func NewCampaign(var _extra):
	for c in new_campaign.get_node("Container").get_children():
		c.queue_free()
	for camp in Global.campaigns:
		var campaign = load("res://scenes/NewCampaignSelector.tscn").instance()
		new_campaign.get_node("Container").add_child(campaign)
		campaign.get_node("CampaignName").text = camp
		var levels = campaign.get_node("LevelsContainer")
		var levels2 = campaign.get_node("LevelsContainer2")
		var l1 = levels.get_node("L1")
		var missions_in_campaign = Global.campaigns[camp]["missions"].size()
		for i in range(2,missions_in_campaign+1):
			var new_l = l1.duplicate(DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS)
			new_l.text = String(i)
			if i <= 10:
				levels.add_child(new_l)
			else:
				levels2.add_child(new_l)

func CampaignEditor(var extra):
	foot_label.visible = false
	if extra is String:
		camp_editor.dedictionise(Global.campaigns[extra])
	else:
		camp_editor.set_new()
		
func LoadGame(var _extra):
	var sls = load("res://scenes/SaveLoadSelector.tscn")
	for c in load_vbox.get_children():
		c.name = "deleted"
		c.queue_free()
	load_vbox.add_child(HSeparator.new())
	for key in Global.saves:
		var inst = sls.instance()
		inst.name = String(key)
		load_vbox.add_child(inst, true)
		load_vbox.add_child(HSeparator.new())
		
	if len(Global.saves) == 0:
		show_menu("MainMenu")
		
func Settings(var _extra):
	setings.show_settings()
		
# Inputs

func _on_Editor_pressed():
	show_menu("CampaignManager")

func _on_Back_pressed():
	show_menu("MainMenu")
	
func _on_Load_pressed():
	show_menu("LoadGame")
	
func _on_NewCampaign_pressed():
	show_menu("NewCampaign")
	
func _on_Settings_pressed():
	show_menu("Settings")

func _on_Exit_pressed():
	get_tree().quit()

func _on_Credits_pressed():
	show_menu("Credits")
