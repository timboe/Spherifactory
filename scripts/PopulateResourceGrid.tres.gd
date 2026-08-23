extends GridContainer

var all_recipes_level := 0

func update_grid():
	for c in get_children():
		c.name = "deleted"
		c.queue_free()
	if name == "FactoryGrid" or name == "NewRecipiesGrid" or name == "TransmuteGrid":
		update_grid_factory(null, false)
	elif name == "AllRecipesGrid":
		update_grid_factory_allrecipes()
	elif name == "ExportedResourcesGrid":
		update_grid_exported()
	else:
		update_grid_resource()

func include_recipe(var r : String ):
	if not Global.sandbox and not name == "AllRecipesGrid":
		var this_level = Global.mission["recipies"]
		if not r in this_level:
			return false 
	if name == "TransmuteGrid":
		if Global.recipies[r]["factory"] == true:
			return false
	elif name == "FactoryGrid":
		if Global.recipies[r]["factory"] == false:
			return false
	if name == "NewRecipiesGrid":
		if Global.level > 0:
			for l in range(0, Global.level):
				if r in Global.campaign["missions"][l]["recipies"]:
					return false
	if name == "AllRecipesGrid":
		if all_recipes_level > 0:
			for l in range(0, all_recipes_level):
				if r in Global.campaign["missions"][l]["recipies"]:
					if Global.DEBUG:
						print("exclude 2 ",r," for level ",all_recipes_level)
					return false
	return true

func update_grid_factory_allrecipes():
	if Global.sandbox:
		update_grid_factory(null, false)
		return
	for l in range(Global.level+1):
		all_recipes_level = l
		var lab = Label.new()
		lab.text = tr("ui_level") + " " + String(l+1)
		var hs1 = HSeparator.new()
		var hs2 = HSeparator.new()
		var hs3 = HSeparator.new()
		var hs4 = HSeparator.new()
		hs1.rect_min_size.x = 64
		hs2.rect_min_size.x = 64
		hs3.rect_min_size.x = 64
		hs4.rect_min_size.x = 64
		add_child(hs1)
		add_child(Label.new())
		add_child(hs2)
		add_child(Label.new())
		add_child(lab)
		add_child(Label.new())
		add_child(hs3)
		add_child(Label.new())
		add_child(hs4)
		update_grid_factory(Global.campaign["missions"][l]["recipies"], true)

func update_grid_factory(var filter, var use_filter):
	for key in Global.recipies:
		if use_filter and not key in filter:
			continue
		if include_recipe(key):
			# B + B + B + B = B = 9 entries in the grid
			var recipe = Global.recipies[key]
			var entries = 0
			# Output - top
			var out_txt = Label.new()
			out_txt.text = String(recipe["amount_out"]) + "x " + String(recipe["time"]) + "s"
			out_txt.align = HALIGN_CENTER
			add_child(out_txt)
			add_child(Label.new()) # =
			entries += 2
			# Input - top
			for ai in range(recipe["amount_in"].size()):
				var in_txt = Label.new()
				in_txt.text = String(recipe["amount_in"][ai]) + "x"
				in_txt.align = HALIGN_CENTER
				add_child(in_txt)
				entries += 1
				if ai != recipe["amount_in"].size() - 1: # If not last
					add_child(Label.new()) # +
					entries += 1
			while entries < 9:
				add_child(Label.new()) # +
				entries += 1
			# Output - bottom
			entries = 0
			var n
			if name == "FactoryGrid":
				n = Button.new()
				n.rect_min_size = Vector2(64,64)
				n.expand_icon = true
				n.icon = Global.data[ key ]["texture"]
				n.name = key
				n.set_script(load("res://scripts/NewBuildingModeButton.gd"))
				n.connect("pressed", n, "_on_Button_pressed")
			else:
				n = TextureRect.new()
				n.rect_min_size = Vector2(64,64)
				n.expand = true
				n.texture = Global.data[ key ]["texture"]
			add_child(n)
			var out_txt2 = Label.new()
			out_txt2.text = "="
			out_txt2.align = HALIGN_CENTER
			add_child(out_txt2)
			entries += 2
			# Input - bottom
			for i in recipe["input"]:
				var tr := TextureRect.new()
				tr.rect_min_size = Vector2(64,64)
				tr.expand = true
				tr.texture = Global.data[ i ]["texture"]
				add_child(tr)
				entries += 1
				if i != recipe["input"][ recipe["input"].size() - 1 ]: # If not last
					var in_txt2 = Label.new()
					in_txt2.align = HALIGN_CENTER
					in_txt2.text = "+"
					add_child(in_txt2)
					entries += 1
			while entries < 9:
				add_child(Label.new()) # =
				entries += 1

func include_resource(var r : String ):
	if not Global.sandbox:
		var this_level = Global.mission["resources"]
		if not r in this_level:
			return false 
	if Global.data[r]["special"]:
		return false
	if name == "ExtractorGrid" or name == "ExportedResourcesGrid":
		if Global.data[r]["mode"] == "-":
			return false
	elif name == "InserterGrid":
		if Global.data[r]["mode"] == "+":
			return false
	elif name == "NewResourcesGrid":
		if Global.level > 0:
			for l in range(0, Global.level):
				if r in Global.campaign["missions"][l]["resources"]:
					return false
	return true

func update_grid_resource():
	for key in Global.data:
		if include_resource(key):
			var n
			if name == "ExtractorGrid" or name == "InserterGrid":
				n = Button.new()
				n.expand_icon = true
				n.rect_min_size = Vector2(64,64)
				n.icon = Global.data[key]["texture"]
				n.name = key
				n.set_script(load("res://scripts/NewBuildingModeButton.gd"))
				n.connect("pressed", n, "_on_Button_pressed")
			else:
				n = TextureRect.new()
				n.expand = true
				n.rect_min_size = Vector2(64,64)
				n.texture = Global.data[key]["texture"]
			add_child(n)

func update_grid_exported():
	for key in Global.data:
		if include_resource(key):
			var n = TextureRect.new()
			n.expand = true
			n.rect_min_size = Vector2(64,64)
			n.texture = Global.data[key]["texture"]
			n.name = key
			add_child(n)
			var mc = MarginContainer.new()
			mc.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
			mc.size_flags_vertical = SIZE_FILL
			var pb = ProgressBar.new()
			pb.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
			pb.size_flags_vertical = SIZE_FILL
			pb.percent_visible = false
			var lbl = Label.new()
			lbl.size_flags_horizontal = SIZE_FILL | SIZE_EXPAND
			lbl.size_flags_vertical = SIZE_FILL
			lbl.align = HALIGN_CENTER
			lbl.valign = VALIGN_CENTER
			mc.add_child(pb)
			mc.add_child(lbl)
			add_child(mc)


