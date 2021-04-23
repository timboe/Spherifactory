extends Button

onready var id : WindowDialog = get_tree().get_root().find_node("InfoDialog",true,false)

func _on_Button_pressed():
	var i : int = name.to_int() - 1

	var lane : MultiMeshInstance2D = id.current_lanes[i]
	print("Binning lane ",i," which is ", lane)
	# This call handles things which export to the lane
	lane.deregister_resource()
	id.update_diag()
	# These calls handle things also which take from the lane
	for f in get_tree().get_nodes_in_group("FactoryGroup"):
		f.lane_cleared(lane)
	$"/root/Game/SomethingChanged".something_changed()
	
func _on_RemoveAll_pressed():
	for l in id.current_lanes:
		if l.lane_content != null:
			l.deregister_resource()
	for f in id.current_ring.get_factories():
		f.remove()
	id.hide_diag()
	$"/root/Game/SomethingChanged".something_changed()
