extends Node2D

onready var id : WindowDialog = get_tree().get_root().find_node("InfoDialog", true, false) 
onready var injection : Node2D = get_tree().get_root().find_node("InjectionSystem", true, false) 
onready var gui_mission : HBoxContainer = get_tree().get_root().find_node("MissionGUIContainer", true, false) 
onready var gui_goal : TextureRect = get_tree().get_root().find_node("MissionTex", true, false) 
onready var gui_remaining : Label  = get_tree().get_root().find_node("MissionRemaining", true, false) 
onready var gui_mission_label : Label  = get_tree().get_root().find_node("MissionLabel", true, false) 
onready var gui_sandbox : Button  = get_tree().get_root().find_node("SandboxButton", true, false) 
onready var rs = get_tree().get_root().find_node("RingSystem", true, false)
onready var save_load = get_tree().get_root().find_node("SaveLoad", true, false)
onready var victory = get_tree().get_root().find_node("Victory", true, false)
onready var something_changed_node = $"/root/Game/SomethingChanged"

var t = 0

func change_level(var level, var with_popup := true):
	var rings : int
	var lanes : int
	var from_above := true
	# Top Gui
	if Global.sandbox:
		Global.mission = null
		Global.remaining = 0
		rings = Global.rings
		lanes = Global.lanes
		from_above = Global.factories_pull_from_above
		gui_sandbox.visible = true
		gui_mission.visible = false
	else:
		if level == Global.campaign["missions"].size():
			# Game finished
			level -= 1
			Global.game_finished = true
		Global.mission = Global.campaign["missions"][level]
		if with_popup and not Global.game_finished: # Otherwise already set in SaveLoadSelector
			Global.remaining = Global.mission["goal_amount"]
		gui_sandbox.visible = false
		gui_mission.visible = true
		gui_goal.texture = Global.data[ Global.mission["goal"] ]["texture"]
		gui_remaining.text = "x" + String(Global.remaining)
		gui_mission_label.text = tr("ui_mission_colon") + String(level + 1)
		rings = Global.mission["rings"]
		lanes = Global.mission["lanes"]
		from_above = Global.mission["factories_collect_above"]
	Global.level = level
	# Number of rings
	set_rings(rings)
	# Number of lanes
	set_lanes(lanes)
	# Factory behaviour
	set_factories_collect(from_above)
	# Injectors
	if Global.sandbox:
		set_injectors(Global.sandbox_injectors)
	else:
		set_injectors(Global.mission["input_lanes"])
	# UI elements
	for g in get_tree().get_nodes_in_group("UIGridsGroup"):
		g.update_grid()
	# Show new mission intro
	if with_popup:
		if Global.sandbox:
			print("popup sandbox")
			id.show_named_diag("Sandbox")
			id.tut_max = get_tree().get_nodes_in_group("TutorialGroup").size()
		elif Global.game_finished:
			id.show_named_diag("Win")
		else:
			print("popup mission or tut")
			var tut = get_tutorial_range()
			if tut == [-1,-1]:
				id.tut_max = get_tree().get_nodes_in_group("TutorialGroup").size()
			else:
				id.tut_current = tut[0]
				id.tut_max = tut[1]
			if tut == [-1,-1] or Global.settings["tutorial"] == false:
				id.show_named_diag("Mission")
			else:
				id.show_mission_after_tut = true
				id.show_named_diag("Tutorial")

# A ship has departed
func deposit(var resource : String, var amount : int):
	if not resource in Global.exported:
		Global.exported[resource] = 0
	Global.exported[resource] += amount
	if not Global.sandbox and resource == Global.mission["goal"]:
		Global.to_subtract += amount
		set_process(true)

func get_tutorial_range() -> Array:
	if Global.sandbox or Global.campaign["name"] != "ui_main_campaign":
		return [-1,-1]
	match Global.level:
		0: return [0,5]
		1: return [5,8]
		2: return [8,9]
	return [-1,-1]

func _process(delta):
	t += delta
	while t > 0.1:
		t -= 0.1
		if Global.to_subtract == 0:
			set_process(false)
			return
		var sub = max(1, round(Global.to_subtract * 0.2))
		Global.to_subtract -= sub
		Global.remaining = int(max(0, Global.remaining - sub))
		gui_remaining.text = "x" + String(Global.remaining)
		if Global.remaining == 0: 
			Global.to_subtract = 0
			set_process(false)
			if not Global.game_finished:
				change_level(Global.level + 1)
				victory.play()

func set_injectors(var inj_data):
	for i in range(Global.MAX_INPUT_LANES): 
		var injector : MultiMeshInstance2D = injection.get_node("Injector"+String(i)).get_node("InjectorMm")
		if i < inj_data.size():
			# Change or update
			var res : String = inj_data[i]["resource"]
			var rate : float = max(inj_data[i]["rate"], 0.01)
			injector.update_resource(res, 1.0/rate)
		else:
			injector.update_resource("None", 1.0)

func set_factories_collect(var from_above):
	if Global.factories_pull_from_above == from_above:
		return
	var sc = false
	for f in get_tree().get_nodes_in_group("FactoryProcessGroup"):
		sc = sc or f.reset_inputs()
	if sc:
		something_changed_node.something_changed()
	Global.factories_pull_from_above = from_above

func set_lanes(var l : int):
	Global.lanes = l

	for ring_i in range(rs.get_child_count() -1, -1, -1):
		if ring_i == 0:
			continue
		#print("Processing ring ", ring_i)
		var ring = rs.get_node("Ring"+String(ring_i))
		var lanes = ring.get_node("Rotation/Lanes")
		for lane_i in lanes.get_child_count():
			var lane = lanes.get_child(lane_i)
			if lane == null or not is_instance_valid(lane):
				continue
			if "deleted" in lane.name:
				continue
			if lane_i >= Global.lanes: # Remove
				if lane.lane_content != null:
					lane.deregister_resource()
					id.update_diag()
					something_changed_node.something_changed()
	for o in get_tree().get_nodes_in_group("RingOutlineGroup"):
		o.update()
	for o in get_tree().get_nodes_in_group("RingOutlineHLGroup"):
		o.update()
	for o in get_tree().get_nodes_in_group("RingOutlineITGroup"):
		o.update()
	
func set_rings(var r : int):
	var rs = get_tree().get_root().find_node("RingSystem", true, false)
	r += 1
	Global.rings = r
	# Note iterating backwards to remove ring above before running check_add_remove_ship on ring below
	for i in range(rs.get_child_count() -1, -1, -1):
		if i == 0:
			continue
		var ring = rs.get_node("Ring"+String(i))
		if i >= r: # Disable
			ring.reset()
			ring.visible = false
			ring.set_processing_active(false)
		else:
			ring.visible = true
			ring.set_processing_active(true)
			for f in ring.get_factories():
				f.check_add_remove_ship()

func _on_Game_ready():
	var with_popup = true
	if Global.request_load != null:
		with_popup = false
	change_level(Global.level, with_popup)
	# Load save file
	if Global.request_load != null:
		save_load.do_load()

