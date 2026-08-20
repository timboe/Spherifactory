extends Node2D

const RING_RADIUS := 40
const RING_WIDTH := 20

var transmutes = []
var transmute_lane = []

func _ready():
	var rings = 0
	for c in get_children():
		rings += 1
		c.setup_resource(RING_RADIUS * rings)
	setup_sol()

# Note: Changing level does not affect this - only need to do it once
# Lane 0: Sink of all items
# Lame 7: Source of H
# Lanes 1,2: Transmute #1
# Lanes 3,4: Transmute #2
# Lanes 5,6: Transmute #3
func setup_sol():
	var fancy_sol = get_parent().get_node("Sol")
	fancy_sol.visible = Global.settings["fancy_sun"]
	var sol = get_child(0)
	if sol.get_lane(7).source == false:
		sol.get_lane(7).register_resource("H", null)
		sol.get_lane(7).set_as_source_lane()
	if sol.get_lane(0).sink == false:
		sol.get_lane(0).set_as_sink_lane()
	# Setup transmute
	update_transmute()
	
func update_transmute():
	var sol = get_child(0)
	for i in range(1,7):
		if sol.get_lane(i).lane_content != null:
			sol.get_lane(i).deregister_resource()
			
	transmutes.clear()
	transmute_lane.clear()
	for _i in range(Global.MAX_TRANSMUTE):
		transmutes.append("None")
		transmute_lane.append(null)
			
	var next_out := 1
	var next_in := 2
	var n_transmute := 0
	for r in Global.recipies:
		if Global.recipies[r]["factory"] == true:
			continue
		
		n_transmute += 1
		if n_transmute > Global.MAX_TRANSMUTE:
			print("ERROR: more than ",Global.MAX_TRANSMUTE," transmutations")
			break
			
		var tranmute_from = Global.recipies[r]["input"][0]
		var transmute_to = r
		
		transmutes[n_transmute-1] = transmute_to
		transmute_lane[n_transmute-1] = sol.get_lane(next_out)
		
		sol.get_lane(next_out).register_resource(transmute_to, null)
		sol.get_lane(next_out).forbid_send = true
		
		# Reset the sink flag such that we can register_resource
		sol.get_lane(next_in).sink = false
		sol.get_lane(next_in).register_resource(tranmute_from, null)

		# Any "tranmute_from" deposited in lane "next_in" becomes "transmute_to" in lane "next_out
		sol.get_lane(next_in).set_laneswap( sol.get_lane(next_out) )
		
		next_out += 2
		next_in += 2

func update_grid():
	update_transmute()
