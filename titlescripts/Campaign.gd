extends CenterContainer

onready var campaign_name : LineEdit = find_node("CampaignName",true,false)
onready var missions_in_campaign : HSlider = find_node("Missions",true,false)
onready var tab_container : TabContainer = find_node("TabContainer", true, false)
onready var hints : WindowDialog = find_node("Hints", true, false)

func reset():
	Global.campaign = null
	Global.data = null
	Global.recipies = null
	campaign_name.text = ""
	missions_in_campaign.value = 1
	for c in tab_container.get_children():
		c.name = "deleted"
		c.queue_free()
	var new_tab = load("res://scenes/MissionConfiguration.tscn").instance()
	new_tab.name = "1"
	tab_container.add_child(new_tab, true)
	
func update_resource_recipy():
	for n in get_tree().get_nodes_in_group("ResRecUpdateGroup"):
		n.update_resource_recipy()
	# Note: Can not cache
	var tab_container_nocache = get_tree().get_root().find_node("TabContainer", true, false)
	for m in tab_container_nocache.get_children():
		if not is_instance_valid(m):
			continue
		var m_c = m.find_node("MissionContainer", true, false)
		if m_c != null:
			m_c.update_configuration()

func set_new():
	reset()
	Global.set_basics()
	update_resource_recipy()

func dedictionise(var load_campaign : Dictionary):
	reset()
	if not dedictionise_internal(load_campaign):
		set_new()
	
func dedictionise_internal(var load_campaign : Dictionary) -> bool:
	Global.campaign = load_campaign
	if not "name" in load_campaign:
		return false
	
	campaign_name.text = tr(load_campaign["name"])

	if not "missions" in load_campaign:
		return false
		
	missions_in_campaign.value = load_campaign["missions"].size()
	# This adds the new tabs
	
	if not "resources" in load_campaign or not "recipies" in load_campaign:
		return false
	
	# Set main arrays
	Global.populate_data()
	update_resource_recipy()
	
	var mission_number = 0
	for mission in load_campaign["missions"]:
		if not "goal" in mission or not "goal_amount" in mission or not "lanes" in mission \
			or not "rings" in mission or not "factories_collect_above" in mission or not "input_lanes" in mission \
			or not "recipies" in mission or not "resources" in mission:
				return false
		
		var new_tab = tab_container.get_node(String(mission_number + 1))
		
		hints.hints_array[mission_number].clear()
		hints.hints_array[mission_number].append_array( mission["hints"] )
		
		mission_number += 1
		
		var g = new_tab.find_node("GoalButton")
		for i in range(g.get_item_count()):
			if g.get_item_metadata(i) == mission["goal"]:
				g.select(i)
				break

		new_tab.find_node("GoalButton").text = mission["goal"] + Global.data[mission["goal"]]["mode"]
		new_tab.find_node("GoalAmountSlider").value =  mission["goal_amount"]
		new_tab.find_node("LanesSlider").value  =  mission["lanes"]
		new_tab.find_node("RingsSlider").value =  mission["rings"]
		new_tab.find_node("Above").pressed = mission["factories_collect_above"]
		
		var inputs_node : GridContainer = new_tab.find_node("InputGridContainer",true,false)
		var input_number = 0
		for input_dict in mission["input_lanes"]:
			if not "resource" in input_dict or not "rate" in input_dict:
				return false
			var menu_button = inputs_node.get_node("Input" + String(input_number) + "/OptionButton")
			for i in range(menu_button.get_item_count()):
				if menu_button.get_item_metadata(i) == input_dict["resource"]:
					menu_button.select(i)
					break
			menu_button.text = input_dict["resource"] + Global.data[input_dict["resource"]]["mode"]
			inputs_node.get_node("Input" + String(input_number) + "/RateSlider").value = input_dict["rate"]
			input_number += 1
			
		var recipies : GridContainer = new_tab.find_node("RecipiesGridContainer",true,false)
		recipies.update_resource_recipy()
		for r in mission["recipies"]:
			var cb : CheckBox = recipies.get_node(r)
			cb.pressed = true
			
		var resources : GridContainer = new_tab.find_node("ResourceGridContainer",true,false)
		resources.update_resource_recipy()
		for r in mission["resources"]:
			var cb : CheckBox = resources.get_node(r)
			cb.pressed = true
			
		var mission_container : VBoxContainer = new_tab.find_node("MissionContainer",true,false)
		mission_container.call_deferred("update_configuration")
		
	return true
	

func dictionise() -> Dictionary:
	var result := {}
	
	result["name"] = campaign_name.text
	if result["name"] == tr("ui_main_campaign"):
		result["name"] = "ui_main_campaign"
	result["version"] = Global.CAMPAIGN_FORMAT_VERSION
	
	var missions := []
	var mission_number = 0
	for mission in tab_container.get_children():
		var mission_dict := {}
		mission_dict["goal"] = mission.find_node("GoalButton").get_selected_metadata()
		mission_dict["goal_amount"] = mission.find_node("GoalAmountSlider").value
		mission_dict["lanes"] = mission.find_node("LanesSlider").value
		mission_dict["rings"] = mission.find_node("RingsSlider").value
		mission_dict["factories_collect_above"] = mission.find_node("Above").pressed
		#
		var lanes := []
		var inputs_node : GridContainer = mission.find_node("InputGridContainer",true,false)
		for i in range(Global.MAX_INPUT_LANES):
			var input_resource = inputs_node.get_node("Input" + String(i) + "/OptionButton").get_selected_metadata()
			if input_resource == "None":
				continue
			var input_rate = inputs_node.get_node("Input" + String(i) + "/RateSlider").value
			var lane_dict := {}
			lane_dict["resource"] = input_resource
			lane_dict["rate"] = input_rate
			lanes.append(lane_dict)
		mission_dict["input_lanes"] = lanes
		#
		var recipies := []
		for c in mission.find_node("RecipiesGridContainer",true,false).get_children():
			if c is CheckBox and c.pressed:
				recipies.append(c.name)
		mission_dict["recipies"] = recipies
		#
		var resources := []
		for c in mission.find_node("ResourceGridContainer",true,false).get_children():
			if c is CheckBox and c.pressed:
				resources.append(c.name)
		mission_dict["resources"] = resources
		#
		mission_dict["hints"] = hints.hints_array[mission_number]
		#
		missions.append(mission_dict)
		mission_number += 1
	result["missions"] = missions
	
	result["recipies"] = Global.recipies
	result["resources"] = Global.data

	return result
	
func flush_campaign_to_disk():
	var file = File.new()
	file.open(Global.CAMPAIGN_SAVE_FILE, File.WRITE)
	file.store_string(JSON.print(Global.campaigns))
	file.close()
