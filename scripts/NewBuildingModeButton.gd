extends Button

onready var id : WindowDialog = get_tree().get_root().find_node("InfoDialog",true,false)

func _on_Button_pressed():
	var mode : int
	if get_parent().name == "ExtractorGrid":
		mode = Global.BUILDING_EXTRACTOR
	elif get_parent().name == "InserterGrid":
		mode = Global.BUILDING_INSERTER
	elif get_parent().name == "FactoryGrid":
		mode = Global.BUILDING_FACTORY
	else:
		print("ERROR in assigning new building job")
	id.current_building.configure_building(mode, name)
	id.hide_diag()
