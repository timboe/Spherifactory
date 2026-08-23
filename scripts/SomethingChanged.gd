extends Timer

onready var id = get_tree().get_root().find_node("InfoDialog", true, false)

# Called from InjectorMultimesh - new input into lane
# Called from BinLane - lane reset
# Called from Factory - I/O changed which could affect other factories
func something_changed():
	start()

func _on_SomethingChanged_timeout():
	#print("Something changed!")
	for f in get_tree().get_nodes_in_group("FactoryProcessGroup"):
		if is_instance_valid(f) and not "deleted" in f.name:
			f.lane_system_changed()
	for r in get_tree().get_nodes_in_group("RingGroup"):
		if is_instance_valid(r):
			r.lane_system_changed()
	# Batched refresh of the lane-content bars (was a synchronous fan-out
	# per register/deregister in RingMultimesh - now coalesced here)
	for c in get_tree().get_nodes_in_group("RingContentGroup"):
		c.update_content()
	id.update_diag()
