extends Button

onready var id : WindowDialog = get_tree().get_root().find_node("InfoDialog",true,false)
onready var sc : Timer = get_tree().get_root().find_node("SomethingChanged",true,false)

func _on_Button_pressed():
	var i : int = name.to_int() - 1
	var lane : MultiMeshInstance2D = id.current_lanes[i]
	if Global.DEBUG:
		print("Binning lane ",i," which is ", lane)
	lane.deregister_resource()
	common()
	
func _on_RemoveAll_pressed():
	id.current_ring.reset()
	if Global.DEBUG:
		print("remove all")
	common()

func common():
	id.hide_diag()
	sc.something_changed()
	for c in get_tree().get_nodes_in_group("RingContentGroup"):
		if is_instance_valid(c):
			c.update_content()
