extends Node2D

onready var id : WindowDialog = get_tree().get_root().find_node("InfoDialog", true, false) 
onready var rule_changer = get_tree().get_root().find_node("RuleChanger", true, false)

func save(var slot, var autosave = false):
	var save_dict = {}
	save_dict["autosave"] = autosave
	save_dict["sandbox"] = Global.sandbox
	save_dict["level"] = Global.level
	save_dict["time_played"] = Global.time_played
	# This bundles all recipy, mission, resource data. In case it were to change...
	save_dict["campaign"] = Global.campaigns[ Global.campaign["name"] ].duplicate(true)
	save_dict["campaign_name"] = Global.campaign["name"]
	save_dict["version"] = Global.SAVE_FORMAT_VERSION
	
	save_dict["sandbox_injectors"] = Global.sandbox_injectors # Only needed for sandbox
		
	save_dict["remaining"] = Global.remaining # only needed for campaign
	save_dict["to_subtract"] = Global.to_subtract # Only needed for campaign
	save_dict["game_finished"] = Global.game_finished # Only needed for campaign
	# Remember what has been exported so far
	save_dict["rings"] = Global.rings - 1 # Only needed for sandbox. Subtract the Sol ring
	save_dict["lanes"] = Global.lanes # Only needed for sandbox
	save_dict["factories_pull_from_above"] = Global.factories_pull_from_above # Only needed for sandbox
	save_dict["exported"] = Global.exported
	save_dict["tutorial_message"] = Global.tutorial_message
	
	# Save button state
	save_dict["paused"] = get_tree().get_root().find_node("Pause",true,false).pressed
	save_dict["ff"] = get_tree().get_root().find_node("FF",true,false).pressed
	save_dict["outlines"] = get_tree().get_root().find_node("Outlines",true,false).pressed
	
	# Save injectors
	var injector_dict = {}
	for i in get_tree().get_nodes_in_group("InjectorLinesGroup"):
		injector_dict[i.get_parent().name] = i.serialise()
	save_dict["saved_injectors"] = injector_dict
	
	# Save Rigs
	var ring_dict = {}
	for i in get_tree().get_nodes_in_group("RingGroup"):
		ring_dict[i.name] = i.serialise()
	save_dict["saved_rings"] = ring_dict
	
	# Save satelites
	var satelite_dict = {}
	for i in get_tree().get_nodes_in_group("FactoryGroup"):
		if i.name == "FactoryTemplate" or "deleted" in i.name:
			continue
		satelite_dict[i.get_path()] = i.serialise()
	save_dict["saved_satelites"] = satelite_dict
	
	# Save ships
	var ship_dict = {}
	for i in get_tree().get_nodes_in_group("ShipRotationGroup"):
		if i.name == "ShipRotationTemplate":
			continue
		ship_dict[i.get_path()] = i.get_child(0).serialise()
	save_dict["saved_ships"] = ship_dict
	
	if autosave:
		slot = get_autosave_key()
	elif slot == -1:
		slot = get_new_key()

	Global.saves[String(slot)] = save_dict
	
	var img_path : String = "user://save_%04d.png" % int(slot)
	if Global.DEBUG:
		print("save to ",img_path)
	if Global.snap != null:
		Global.snap.save_png(img_path)
	
	var file = File.new()
	file.open(Global.GAME_SAVE_FILE, File.WRITE)
	file.store_string(JSON.print(Global.saves))
	file.close()

func get_autosave_key() -> String:
	for key in Global.saves:
		if Global.saves[String(key)]["autosave"] == true:
			return key
	return get_new_key()
	
func get_new_key() -> String:
	var the_max = -1
	for key in Global.saves:
		the_max = max(the_max, int(key))
	return String(the_max + 1)

func snap():
	Global.snap = get_viewport().get_texture().get_data()
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	Global.snap.flip_y()
	Global.snap.resize(512,300)
	
func do_load():
	# See SaveLoadSelector for initial loading of basics
	#
	var save_version : int = Global.request_load.get("version", -1)
	if save_version != Global.SAVE_FORMAT_VERSION:
		print("ERROR: unsupported save version ", save_version, " (expected ", Global.SAVE_FORMAT_VERSION, ")")
		return
	# Button state
	get_tree().get_root().find_node("Pause",true,false).pressed = Global.request_load["paused"] 
	get_tree().get_root().find_node("FF",true,false).pressed = Global.request_load["ff"]
	get_tree().get_root().find_node("Outlines",true,false).pressed = Global.request_load["outlines"]
	# 
	# First rings
	for i in get_tree().get_nodes_in_group("RingGroup"):
		i.deserialise( Global.request_load["saved_rings"][i.name] )
	# Second injectors
	for i in get_tree().get_nodes_in_group("InjectorLinesGroup"):
		i.deserialise( Global.request_load["saved_injectors"][i.get_parent().name] )
	# Third satelites
	var all_satelite_data = Global.request_load["saved_satelites"]
	for s in all_satelite_data:
		var satelite_data : Dictionary = all_satelite_data[s]
		var parent_ring = get_node(satelite_data["parent_ring"])
		var new_factory = parent_ring.get_node("Rotation/FactoryTemplate").duplicate(DUPLICATE_SCRIPTS|DUPLICATE_SIGNALS|DUPLICATE_GROUPS)
		new_factory.visible = true
		new_factory.name = satelite_data["name"]
		new_factory.get_node("TextureButton").visible = true
		parent_ring.get_node("Rotation/Factories").add_child(new_factory, true)
		new_factory.set_owner(get_tree().get_root())
		new_factory.deserialise(satelite_data)
#		#TODO check and remove this add_to_group line, done in editor
		new_factory.get_node("FactoryProcess").add_to_group("FactoryProcessGroup", true)
		# TODO this is hanging?
		# TODO make ring un-fillable
		for l in parent_ring.get_lanes():
			if "deleted" in l.name or not is_instance_valid(l):
				continue
			l.set_range_fillable(satelite_data["factory_angle_start"], satelite_data["factory_angle_end"], false)
	# Fourth ships
	var all_ships_data = Global.request_load["saved_ships"]
	for s in all_ships_data:
		var ship_data : Dictionary = all_ships_data[s]
		var parent_ring = get_node(ship_data["parent_ring"])
		if ship_data["launch"]: # Launched. Don't re-animate. Just make sure a new ship was spawned
			if not ship_data.get("deposited", false):
				rule_changer.deposit(ship_data["recipe"], ship_data["output_storage"])
		else: # Not launched. Add me
			var sr = parent_ring.get_node("ShipRotationTemplate").duplicate(DUPLICATE_SCRIPTS|DUPLICATE_GROUPS|DUPLICATE_SIGNALS)
			sr.name = ship_data["shiprotator_name"]
			parent_ring.add_child(sr, true)
			sr.set_owner(get_tree().get_root())
			sr.global_rotation = ship_data["shiprotator_global_rotation"]
			sr.get_child(0).deserialise(ship_data) # This adds it to its factory
		id.update_diag()
	# Fifth check if any satelites need new ships
	for f in get_tree().get_nodes_in_group("FactoryGroup"):
		if f.name == "FactoryTemplate" or "deleted" in f.name:
			continue
		f.check_add_remove_ship()
	#
	$"/root/Game/SomethingChanged".something_changed()

func _on_NewSave_pressed():
	save(-1)
	if Global.DEBUG:
		print("new save")
	id.hide_diag()

func _on_Autosave_timeout():
	# snap() is a coroutine (waits two idle frames so the texture is ready).
	# Wait for it to finish BEFORE saving, otherwise the screenshot is
	# written un-flipped and un-resized.
	var snap_state = snap()
	if snap_state != null:
		yield(snap_state, "completed")
	save(-1, true)
