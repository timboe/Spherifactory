extends OptionButton

onready var mission_container : VBoxContainer = find_parent("MissionContainer")

func update_resource_recipy():
	clear() # This is called repeatedly (via ResRecUpdateGroup) - avoid stacking duplicates
	add_item("None", 0)
	set_item_metadata(0, "None")
	var i : int = 1
	for key in Global.data:
		if Global.data[key]["special"] == true:
			continue
		add_item(key + Global.data[key]["mode"], i)
		set_item_metadata(i, key)
		i += 1
		
func _ready():
	update_resource_recipy()
		
func _on_OptionButton_item_selected(index):
	mission_container.update_configuration()
