extends WindowDialog

onready var warn_diag : AcceptDialog = find_parent("CampaignEditor").find_node("WarningDialog", true, false)
onready var tab_container : TabContainer = find_node("TabContainer", true, false)
onready var factory_tab : MarginContainer = find_node("ui_factory", true, false)
onready var transmute_tab : MarginContainer = find_node("ui_transmute", true, false)
onready var name_lineedit : LineEdit = find_node("NameLineEdit", true, false)
onready var campaign_editor : CenterContainer = find_parent("CampaignEditor")

var shown_for

func show_for(var resource):
	# Get current setting
	if not resource in Global.recipies:
		tab_container.current_tab = 0
	elif resource in Global.recipies and Global.recipies[resource]["factory"] == true:
		tab_container.current_tab = 1
	else:
		tab_container.current_tab = 2
	
	name_lineedit.text = resource + Global.data[resource]["mode"]
	shown_for = resource
	
	# Populate factory tab
	for i in range(4):
		var f = factory_tab.find_node("FactoryInput"+String(i),true,false)
		var ob : OptionButton = f.get_node("OptionButton")
		var slider : HSlider = f.get_node("NumberSlider")
		slider.value = 1
		ob.clear()
		ob.add_item("None", 0)
		ob.set_item_metadata(0, null)
		var set_select = 0
		var count = 1
		for r in Global.data:
			if r == resource:
				continue
			if Global.data[r]["special"] == true:
				continue
			ob.add_item(r + Global.data[r]["mode"], count)
			ob.set_item_metadata(count, r)
			if resource in Global.recipies and Global.recipies[resource]["input"].size() > i:
				if Global.recipies[resource]["factory"] == true and Global.recipies[resource]["input"][i] == r:
					set_select = count
					slider.value = Global.recipies[resource]["amount_in"][i]
			count += 1
		ob.select(set_select)
	var out_n : HSlider =  factory_tab.find_node("NumberOut",true,false)
	var out_time : HSlider =  factory_tab.find_node("TimeOut",true,false)
	if resource in Global.recipies:
		out_n.value = Global.recipies[resource]["amount_out"]
		out_time.value = Global.recipies[resource]["time"]
	else:
		out_n.value = 1
		out_time.value = 1
		
	# Populate transmute tab
	var can_t : VBoxContainer =  transmute_tab.find_node("CanTransmute",true,false)
	var cant_t : VBoxContainer =  transmute_tab.find_node("CannotTransmute",true,false)
	var transmute : OptionButton =  transmute_tab.find_node("TransmuteOptionButton",true,false)
	transmute.clear()
	can_t.visible = (Global.data[resource]["mode"] == "+") # Only things which propagate up can be transmuted to
	cant_t.visible = !can_t.visible
	if can_t.visible:
		var count = 0
		var set_select = 0
		for r in Global.data:
			if Global.data[r]["mode"] == "+": # Cannot select anything which propagates up as the input
				continue
			if Global.data[r]["special"] == true:
				continue
			transmute.add_item(r + "-")
			transmute.set_item_metadata(count, r)
			# Check if we already have a transmutation selected
			if resource in Global.recipies and Global.recipies[resource]["factory"] == false:
				if Global.recipies[resource]["input"][0] == r:
					set_select = count
			count += 1
		transmute.select(set_select)

	popup_centered()

func _on_Save_pressed():
	var tab = tab_container.current_tab
	
	if tab == 0:
		if shown_for in Global.recipies:
			Global.recipies.erase(shown_for)
	elif tab == 1:
		var d := {}
		var input_resource = []
		var input_number = []
		for i in range(4):
			var f = factory_tab.find_node("FactoryInput"+String(i),true,false)
			var sel = f.get_node("OptionButton").get_selected_metadata()
			if sel == null:
				continue
			if sel in input_resource: # Each resource can only be used as one input
				continue
			input_resource.append(sel)
			input_number.append(f.get_node("NumberSlider").value)
		d["time"] = factory_tab.find_node("TimeOut",true,false).value
		d["amount_out"] = factory_tab.find_node("NumberOut",true,false).value
		d["amount_in"] = input_number
		d["input"] = input_resource
		d["factory"] = true
		Global.recipies[shown_for] = d
	elif tab == 2:
		# Only MAX_TRANSMUTE (currently 3) things can be transmute. Count (excluding the current thing)
		var where_used = {}
		var current_transmutes = ""
		for r in Global.recipies:
			if r == shown_for:
				continue
			if Global.recipies[r]["factory"] == false:
				var inpt = Global.recipies[r]["input"][0]
				where_used[ inpt ] = r
				current_transmutes += r + Global.data[r]["mode"] + " "
		if where_used.size() >= Global.MAX_TRANSMUTE:
			warn_diag.dialog_text = tr("ui_n_transmute_1") + "\n\n"
			warn_diag.dialog_text += tr("ui_n_transmute_2") + current_transmutes
			warn_diag.popup_centered()
			return
		# Each input can only be used once
		var transmute_input = transmute_tab.find_node("TransmuteOptionButton",true,false).get_selected_metadata()
		if transmute_input in where_used:
			warn_diag.dialog_text = tr("ui_which_transmute_1") + "\n\n"
			warn_diag.dialog_text += tr("ui_which_transmute_2") + transmute_input + Global.data[transmute_input]["mode"] + "\n\n"
			warn_diag.dialog_text += tr("ui_which_transmute_3") + where_used[transmute_input] + Global.data[where_used[transmute_input]]["mode"] + " first."
			warn_diag.popup_centered()
			return
		var d := {}
		d["time"] = 0
		d["amount_out"] = 1
		d["amount_in"] = [1, 1]
		d["input"] = [transmute_input, "Sol"]
		d["factory"] = false
		Global.recipies[shown_for] = d
	else:
		print("ERROR only expecting three recipe tabs")
	campaign_editor.update_resource_recipy()
	hide()

func _on_Discard_pressed():
	hide()

