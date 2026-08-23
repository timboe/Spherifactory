extends Button

onready var id = get_tree().get_root().find_node("InfoDialog", true, false) 

onready var inj_node = get_tree().get_root().find_node("Injector"+String(int(name)), true, false).get_node("InjectorMm")

func _on_Button_toggled(button_pressed):
	if button_pressed:
		# The button calling this method is the one that was just selected
		var pressed_button : Button = group.get_pressed_button()
		if Global.last_pressed == pressed_button:
			# The button calling the method was the last one that was selected (we clicked it twice in a row)
			# Toggle it off and set last_pressed to null so we can click it a third time to toggle it back on
			pressed_button.pressed = false
			button_pressed = false
			Global.last_pressed = null
		# Update the last button pressed if we clicked something different
		else:
			Global.last_pressed = pressed_button
	
	if button_pressed:
		print("build inj hide diag")
		id.hide_diag()
		
	for tb in get_tree().get_nodes_in_group("FactoryButtonGroup"):
		tb.visible = !button_pressed
	
	if name == "BuildMode":
		if button_pressed == false: # Hide all 
			for r in get_tree().get_nodes_in_group("RingGroup"):
				r.set_factory_template_visible(false)
	else: # Inject mode
		# Show injection circle targets
		for r in get_tree().get_nodes_in_group("RingGroup"):
			var it = r.get_node("OutlineInjectorTarget")
			it.set_inject(inj_node.set_resource)
			it.visible = button_pressed
		# Hide if not placed
		if button_pressed == false:
			for il in get_tree().get_nodes_in_group("InjectorLinesGroup"):
				if is_instance_valid(il) and il.get_parent() != null:
					var mm = il.get_parent().get_node_or_null("InjectorMm")
					if mm != null:
						mm.stop_hint_resource()
