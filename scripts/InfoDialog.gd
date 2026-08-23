extends WindowDialog

onready var shields = get_tree().get_root().find_node("Shields", true, false) 
onready var save_vbox = get_tree().get_root().find_node("SaveVBox", true, false) 
onready var load_vbox = get_tree().get_root().find_node("LoadVBox", true, false) 
onready var save_load = get_tree().get_root().find_node("SaveLoad", true, false) 
onready var ring_system = get_tree().get_root().find_node("RingSystem", true, false) 
onready var progress_bar = get_tree().get_root().find_node("FactoryProgressBar", true, false) 
onready var camera_2d := get_tree().get_root().find_node("Camera2D", true, false)

var current_building : Node2D  = null
var current_ring : Node2D = null
var current_lanes : Array = []
var page : String = ""

var sb_gray := StyleBoxFlat.new()
var sb_green := StyleBoxFlat.new()
var sb_blue := StyleBoxFlat.new()
var sb_purple := StyleBoxFlat.new()
var sb_orange := StyleBoxFlat.new()
var sb_red := StyleBoxFlat.new()

var tut_current : int = 0
var tut_max : int =  0
var show_mission_after_tut : bool = false

var first : bool

func _ready():
	sb_gray.bg_color = Color.gray
	sb_green.bg_color = Color.greenyellow
	sb_blue.bg_color = Color.blue
	sb_purple.bg_color =  Color.purple
	sb_orange.bg_color = Color.orange
	sb_red.bg_color = Color.red
	set_process(false)
	
func _process(_delta):
	if page == "Exported":
		return export_process()
	###
	if current_building == null:
		return
	if not is_instance_valid(current_building):
		return
	if "deleted" in current_building.name:
		return
	var timer : Timer = current_building.get_node("FactoryProcess").get_node("Timer")
	if timer.wait_time <= 0.0:
		return
	var percentage = 1.0 - (timer.time_left / timer.wait_time)
	progress_bar.value = percentage

func hide_diag():
	print("hide")
	current_ring = null
	current_building = null
	page = ""
	hide()
	$UpdateTimer.stop()
	set_process(false)
	if show_mission_after_tut:
		_on_Mission_pressed()

func show_shared_internal():
	current_building = null
	current_ring = null
	page = ""
	for c in get_children():
		if c is MarginContainer:
			c.visible = false
	show()

func show_ring_diag(var ring : Node2D):
	show_shared_internal()
	$RingContainer.visible = true
	current_ring = ring
	update_ring_diag()
	
func show_building_diag(var factory : Node2D):
	show_shared_internal()
	$FactoryContainer.visible = true
	current_building = factory
	$UpdateTimer.start()
	set_process(true)
	update_building_diag()
	
func get_title_tr(var w : String):
	if w == "Ring":
		return tr("ui_ring")
	elif  w == "Factory":
		return tr("ui_factory")
	elif  w == "Menu":
		return tr("ui_menu")
	elif  w == "Sandbox":
		return tr("ui_sandbox")
	elif  w == "Mission":
		return tr("ui_current_mission")
	elif  w == "Hints":
		return tr("ui_hints")
	elif  w == "AllRecipes":
		return tr("ui_all_recipes")
	elif w == "Exported" or w == "exported":
		return tr("ui_exported")
	elif  w == "Save":
		return tr("ui_save")
	elif  w == "Load":
		return tr("ui_load")
	elif  w == "Tutorial":
		return tr("ui_tutorial")
	elif  w == "Win":
		return ""
	return ""
		
func toggle_menu_diag():
	var show : bool = (page != "menu")
	if show:
		# Take the screenshot while the dialog is hidden so the thumbnail is clean
		show_mission_after_tut = false
		hide()
		save_load.snap()
	show_shared_internal()
	if show:
		$MenuContainer.visible = true
		page = "menu"
		window_title = get_title_tr("Menu")
		var show_export : bool = (Global.sandbox or Global.game_finished)
		$MenuContainer/Container/GridContainer/Mission.visible = !show_export
		$MenuContainer/Container/GridContainer/Exported.visible = show_export
	else:
		print("toggle menu off")
		hide_diag()

func show_named_diag(var n : String):
	if page == n: # Also acts as a toggle
		print("show named toggle off")
		hide_diag()
		return
	show_shared_internal()
	var node = find_node(n+"Container")
	node.visible = true
	page = n
	window_title = get_title_tr(n)
	if has_method("update_"+n+"_diag"):
		first = true
		call("update_"+n+"_diag")
		
# Used to refresh the page when it is being displyed
func update_diag():
	first = false
	if current_ring != null:
		update_ring_diag()
	elif current_building != null:
		update_building_diag()
	elif page == "Load":
		update_Load_diag()
	else:
		pass

# Below used to update page on initial draw

func update_Win_diag():
	var h : int = int(Global.time_played) / 3600
	var remainder : int = int(Global.time_played) % 3600
	var m = remainder / 60
	var s = remainder % 60
	window_title = tr("ui_congratulations")
	$WinContainer/VBox/FinishedText.text = tr(Global.campaign["name"]) + " " + tr("ui_finished in") + "\n\n"
	$WinContainer/VBox/FinishedText.text += String(h) + " " + tr("ui_hours") + " "
	$WinContainer/VBox/FinishedText.text += String(m) + " " + tr("ui_minutes") + " "
	$WinContainer/VBox/FinishedText.text += String(s) + " " + tr("ui_seconds")
	$WinContainer/Confetti1.emitting = true
	$WinContainer/Confetti2.emitting = true

func update_Tutorial_diag():
	if tut_current == 0:
		window_title = tr("ui_tutorial_welcome")
	else:
		window_title = tr("ui_tutorial_message") + " " + String(tut_current + 1)
	$TutorialContainer/VBox/HBox/ShowTutorialCheckbox.pressed = Global.settings["tutorial"]
	for t in get_tree().get_nodes_in_group("TutorialGroup"):
		var _cur : bool  = (t.name == String(tut_current))
		t.visible = (t.name == String(tut_current))
	$TutorialContainer/VBox/HBox2/Prev.disabled = (tut_current == 0)
	$TutorialContainer/VBox/HBox2/Next.disabled = (tut_current == (tut_max - 1))
	$"TutorialContainer/VBox/TutorialContainerSC/TutorialVBox/7/Label_above".visible = Global.factories_pull_from_above
	$"TutorialContainer/VBox/TutorialContainerSC/TutorialVBox/7/ColorRect_above".visible = Global.factories_pull_from_above
	$"TutorialContainer/VBox/TutorialContainerSC/TutorialVBox/7/Label_below".visible = !Global.factories_pull_from_above
	$"TutorialContainer/VBox/TutorialContainerSC/TutorialVBox/7/ColorRect_below".visible = !Global.factories_pull_from_above	

func update_Save_diag():
	update_SaveLoad_common(save_vbox)

func update_Load_diag():
	update_SaveLoad_common(load_vbox)
	
func update_SaveLoad_common(var vbox):
	var sls = load("res://scenes/SaveLoadSelector.tscn")
	for c in vbox.get_children():
		c.name = "deleted"
		c.queue_free()
	vbox.add_child(HSeparator.new())
	for key in Global.saves:
		var inst = sls.instance()
		inst.name = String(key)
		vbox.add_child(inst, true)
		vbox.add_child(HSeparator.new())

func update_Exported_diag():
	#TODO live updating isn't working well
#	if not "H" in Global.exported:
#		Global.exported["H"] = 50
	set_process(true)

func export_process():
	var g = $ExportedContainer/VBox/ExportedResourceGridSC/ExportedResourcesGrid
	for i in range(0, g.get_child_count(), 2):
		var n : int = 0
		var res = g.get_child(i).name
		if res in Global.exported:
			n = min(Global.exported[res], 100000)
		var current : float = g.get_child(i + 1).get_child(0).value
		var add = max(1, round((n - current) * 0.005))
		if first:
			current = n
		elif not is_equal_approx(current, n):
			current += add
		g.get_child(i + 1).get_child(0).max_value = leet_n(current)
		g.get_child(i + 1).get_child(0).value = current
		g.get_child(i + 1).get_child(0).set("custom_styles/fg", leet_color(current))
		g.get_child(i + 1).get_child(1).text = String(current)

func leet_n(var n : int) -> int:
	if n < 100:
		return 100
	elif n < 500:
		return 500
	elif n < 1000:
		return 1000
	elif n < 5000:
		return 5000
	elif n < 10000:
		return 10000
	else:
		return n

func leet_color(var n : int) -> StyleBoxFlat:
	if n < 100:
		return sb_gray
	elif n < 500:
		return sb_green
	elif n < 1000:
		return sb_blue
	elif n < 5000:
		return sb_purple
	elif n < 10000:
		return sb_orange
	else:
		return sb_red

func include_recipe(var r : String ):
	if not Global.sandbox:
		var this_level = Global.mission["recipies"]
		if not r in this_level:
			return false
	return true

func update_Sol_diag():
	window_title = tr("ui_sol")
	$UpdateTimer.start()
	$SolContainer/VBoxContainer/GridContainer/HIcon.texture = Global.data["H"]["texture"]
	var sol = ring_system.get_child(0)
	$SolContainer/VBoxContainer/GridContainer/Count1/Mm.set_lane_resource(sol.get_lane(1))
	$SolContainer/VBoxContainer/GridContainer/Count2/Mm.set_lane_resource(sol.get_lane(3))
	$SolContainer/VBoxContainer/GridContainer/Count3/Mm.set_lane_resource(sol.get_lane(5))
	for i in range(3):
		var icon = get_node("SolContainer/VBoxContainer/GridContainer/TransIcon"+String(i+1))
		if ring_system.transmutes[i] != "None" and include_recipe(ring_system.transmutes[i]):
			icon.texture = Global.data[ ring_system.transmutes[i] ]["texture"]
		else:
			icon.texture = Global.data["None"]["texture"]
	
func update_Mission_diag():
	$MissionContainer/VBox/CampaignName.text = tr(Global.campaign["name"])
	var level_str = String(Global.level + 1) + " of " + String(Global.campaign["missions"].size())
	$MissionContainer/VBox/InfoGrid/MissionNumber.text = level_str
	$MissionContainer/VBox/InfoGrid/Rings.text = String(Global.rings - 1) # Avoid Sol
	$MissionContainer/VBox/InfoGrid/Lanes.text = String(Global.lanes)
	var from_above_str = tr("ui_from_above") if Global.factories_pull_from_above else tr("ui_from_below")
	$MissionContainer/VBox/InfoGrid/FromAbove.text = from_above_str
	var goal_res = Global.mission["goal"]
	var goal_amount = Global.mission["goal_amount"]
	print("goal res ", goal_res)
	$MissionContainer/VBox/HBottomBox/GoalTextureRect.texture = Global.data[ goal_res ]["texture"]
	$MissionContainer/VBox/HBottomBox/GoalNumber.text = "x" + String(goal_amount)

func update_building_diag():
	window_title = current_building.descriptive_name
	if current_building.mode == Global.BUILDING_UNSET:
		$FactoryContainer/Unset.visible = true
		$FactoryContainer/Set.visible = false
	else:
		$FactoryContainer/Unset.visible = false
		$FactoryContainer/Set.visible = true
		# Inputs
		if current_building.mode == Global.BUILDING_FACTORY:
			$FactoryContainer/Set/Inputs.visible = true
			var count = 0
			for i in range(current_building.get_process_node().input_content.size()):
				var cont = get_node("FactoryContainer/Set/Inputs/GridContainer/I"+String(i))
				var mm = cont.get_node("Count/Mm")
				var ico = cont.get_node("Icon")
				var resource = current_building.get_process_node().input_content[i]
				cont.visible = true
				ico.texture = Global.data[resource]["texture"]
				mm.set_resource(resource, current_building.get_process_node(), true, i)
				count += 1
			while count < 4:
				var cont = get_node("FactoryContainer/Set/Inputs/GridContainer/I"+String(count))
				cont.visible = false
				count += 1
		else:
			$FactoryContainer/Set/Inputs.visible = false
		# Output
		var out_cont = get_node("FactoryContainer/Set/Output/OutAndShip/Out")
		var output = current_building.get_process_node().output_content
		var out_mm = out_cont.get_node("Count/Mm")
		var out_ico = out_cont.get_node("Icon")
		out_ico.texture = Global.data[output]["texture"]
		out_mm.set_resource(output, current_building.get_process_node())
		# Output with Ship
		var ship_cont = get_node("FactoryContainer/Set/Output/OutAndShip/Ship")
		var ship = current_building.get_node("FactoryProcess").ship
		if ship != null and is_instance_valid(ship):
			print("Showing ship detail")
			ship_cont.visible = true
			var mm = ship_cont.get_node("Count/Mm")
			var ship_ico = ship_cont.get_node("Ship/Ship")
			ship_ico.set_resource(output)
			mm.set_resource(output, ship)
		else:
			print("Not showing ship detaild due to ship ", ship)
			ship_cont.visible = false
		# Follow 
		camera_2d.ignore = true
		$FactoryContainer/Set/HBoxContainer2/Rotate.pressed = (camera_2d.follow_target == current_building)
		camera_2d.ignore = false

func update_ring_diag():
	var count : int = 1
	window_title = tr("ui_ring") + String(current_ring.ring_number)
	current_lanes.clear()
	for l in current_ring.get_lanes():
		if not is_instance_valid(l):
			continue
		# current_lanes is used by the bin script
		current_lanes.append(l)
		var tex : ImageTexture = null
		if l.lane_content != null:
			tex = Global.data[l.lane_content]["texture"]
		else:
			tex = Global.data["None"]["texture"]
		var icon : Node = find_node("LIcon"+String(count))
		if icon != null:
			icon.texture = tex
		var bin : Button = find_node("LBin"+String(count))
		if bin != null:
			bin.disabled = (l.lane_content == null)
		#
		var list : ItemList = $RingContainer/VBoxContainer/ScrollContainer/FactoriesList
		list.clear()
		var s_count := 0
		for s in current_ring.get_factories():
			list.add_item(s.descriptive_name)
			list.set_item_metadata(s_count, s)
			s_count += 1
		#
		count += 1
		
func update_Sandbox_diag():
	$SandboxContainer/VBoxContainer/FactoryBehaviour/Above.pressed = Global.factories_pull_from_above
	$SandboxContainer/VBoxContainer/Lane/LanesSlider.value = Global.lanes
	$SandboxContainer/VBoxContainer/Ring/RingsSlider.value = Global.rings - 1
	
func update_Hints_diag():
	var scram_options = ["*", "!", "?", "#"] 
	var scram = scram_options[ randi() % scram_options.size() ]
	var scrambied : Array
	for i in range(3):
		var processed : String = ""
		for c in Global.mission["hints"][i]:
			if c == " ":
				scram = scram_options[ randi() % scram_options.size() ]
				processed += " "
			else:
				processed += scram
		scrambied.append(processed)
	$HintsContainer/VBoxContainer/HBox1/HintEdit1.text = scrambied[0]
	$HintsContainer/VBoxContainer/HBox2/HintEdit2.text = scrambied[1]
	$HintsContainer/VBoxContainer/HBox3/HintEdit3.text = scrambied[2]
	$HintsContainer/VBoxContainer/HBox1/Show1.disabled = false
	$HintsContainer/VBoxContainer/HBox2/Show2.disabled = true
	$HintsContainer/VBoxContainer/HBox3/Show3.disabled = true

func _on_UpdateTimer_timeout():
	if current_building != null or page == "Sol":
		for mm in get_tree().get_nodes_in_group("InfoMultimeshGroup"):
			if is_instance_valid(mm):
				mm.update_visible()

func _on_Sandbox_pressed():
	show_named_diag("Sandbox")

func _on_Mission_pressed():
	show_named_diag("Mission")
	show_mission_after_tut = false

func _on_Title_pressed():
	get_tree().paused = false
	Global.goto_scene("res://Title.tscn")

func _on_Quit_pressed():
	get_tree().quit()

func _on_Back_pressed():
	if show_mission_after_tut:
		_on_Mission_pressed()
	else:
		toggle_menu_diag()

func _on_Exported_pressed():
	show_named_diag("Exported")

func _on_Save_pressed():
	show_named_diag("Save")

func _on_Load_pressed():
	show_named_diag("Load")

func _on_Tutorial_pressed():
	show_named_diag("Tutorial")

func _on_Next_pressed():
	tut_current += 1 
	update_Tutorial_diag()

func _on_Prev_pressed():
	tut_current -= 1 
	update_Tutorial_diag()

func _on_AllRecipes_pressed():
	show_named_diag("AllRecipes")

func _on_ClearAll_pressed():
	hide_diag()
	for r in get_tree().get_nodes_in_group("RingGroup"):
		if r == null or not is_instance_valid(r) or r.name == "Ring0":
			continue
		r.reset()
	$"/root/Game/SomethingChanged".something_changed()
	for c in get_tree().get_nodes_in_group("RingContentGroup"):
		c.update_content()

func _on_Hints_pressed():
	show_named_diag("Hints")


func _on_Show1_pressed():
	$HintsContainer/VBoxContainer/HBox1/Show1.disabled = true
	$HintsContainer/VBoxContainer/HBox2/Show2.disabled = false
	$HintsContainer/VBoxContainer/HBox1/HintEdit1.text = Global.mission["hints"][0]

func _on_Show2_pressed():
	$HintsContainer/VBoxContainer/HBox2/Show2.disabled = true
	$HintsContainer/VBoxContainer/HBox3/Show3.disabled = false
	$HintsContainer/VBoxContainer/HBox2/HintEdit2.text = Global.mission["hints"][1]

func _on_Show3_pressed():
	$HintsContainer/VBoxContainer/HBox3/Show3.disabled = true
	$HintsContainer/VBoxContainer/HBox3/HintEdit3.text = Global.mission["hints"][2]

func _on_Clear_pressed():
	current_building.reset()
	hide_diag()


func _on_Remove_pressed():
	current_building.remove()
	hide_diag()



func _on_Close_pressed():
	hide_diag()
