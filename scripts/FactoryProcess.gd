extends Node2D
tool

onready var ring := find_parent("Ring*") as Node2D
onready var something_changed_node = $"/root/Game/SomethingChanged"

var input_factory_required = [] # Number of items required per input for factory mode
var input_storage = [] # Number of stored items per input
var input_content = [] # List of strings, name of each input
var input_lanes = [] # This is a list of lists. Providers of each input
var input_lanes_distance = [] # This is a list of lists. How far away are each provider (1 or 2)

var spies = [] # The multimeshes currently spying on the storage content here
var ship = null

export(float) var angle_back
export(float) var angle_front

export(int) var output_amount = 0 # Just for factory mode
export(int) var output_storage = 0
export(String) var output_content = null
export(int) var output_direction = null
var output_lane : Node2D = null

export(int) var mode = Global.BUILDING_UNSET

func reset():
	#
	remove_any_ship() # Note do this first (before dereg providers)
	#
	input_content.clear()
	input_storage.clear()
	input_lanes.clear()
	input_lanes_distance.clear()
	input_factory_required.clear()
	#
	# If we currently have a registered output, then we should clear it now
	if output_lane != null and is_instance_valid(output_lane):
		output_lane.deregister_provider(self)
	output_amount = 0
	output_storage = 0
	output_content = null
	output_direction = null
	output_lane = null
	#
	# Cannot iterate over a collection which is being erased. Iterate over dupe
	var spies_copy : Array = spies.duplicate()
	for spy in spies_copy:
		spy.reset()
	spies.clear() # Shoule be alreay cleared...
	#
	mode = Global.BUILDING_UNSET # Note: do this last

func set_spy(var spy):
	spies.append(spy)
	
func remove_spy(var spy):
	spies.erase(spy)
	
func remove_any_ship():
	if ship != null and is_instance_valid(ship):
		print("Ship removed by ring")
		ship.remove()
	ship = null
	
func configure(var _mode : int, var recipy : String):
	reset()
	mode = _mode
	if mode == Global.BUILDING_FACTORY:
		$Timer.wait_time = Global.recipies[recipy]["time"]
		output_amount = Global.recipies[recipy]["amount_out"]
		for i in Global.recipies[recipy]["input"].size():
			input_content.append(Global.recipies[recipy]["input"][i])
			input_storage.append(0)
			input_factory_required.append(Global.recipies[recipy]["amount_in"][i])
			input_lanes.append([])
			input_lanes_distance.append([])
	else:
		input_content.append(recipy) # recipy is just the thing we are moving
		input_storage.append(0)
		input_lanes.append([])
		# input_lanes_distance not used
		# input_factory_required not used
		# output_amount not used
	# Output
	output_content = recipy
	output_storage = 0
	output_lane = null
	lane_system_changed()
	
func lane_cleared(var lane_or_ship : Node2D):
	if mode == Global.BUILDING_UNSET: # Called on all buildings by the Bin fn
		return
	var something_changed : bool = false
	if output_lane == lane_or_ship:
		output_lane = null
		print("ship = null by lane_cleared, was ", ship)
		ship = null
		something_changed = true
	for input_resource in input_lanes:
		for idx in range(input_resource.size() -1, -1):
			if input_resource[idx] == lane_or_ship:
				input_resource.remove(idx)
				something_changed = true
	check_process()
	if something_changed:
		something_changed_node.something_changed()

func lane_system_changed():
	if mode == Global.BUILDING_UNSET: # Called on all buildings by SomethingChanged
		return
	var something_changed = false
	# Input
	if mode == Global.BUILDING_FACTORY:
		# We check the two outermost rings for input
		var distance : int = 0 # One or two. Factories can reach over 1 ring
		for ring_idx in range(ring.ring_number + 1, ring.ring_number + 3):
			if ring_idx >= Global.rings:
				break
			distance += 1
			for l in ring.get_parent().get_child(ring_idx).get_lanes():
				if l.lane_content == null:
					continue
				for input_idx in range(input_content.size()):
					if l.lane_content == input_content[input_idx]:
						if not input_lanes[input_idx].has(l):
							input_lanes[input_idx].append(l)
							input_lanes_distance[input_idx].append(distance)
							print("The ",name," will now import ",input_content[input_idx]," from ",l," (total of ",input_lanes[input_idx].size()," sources)")
							something_changed = true
	else: # Inserter or extractor
		input_lanes.append([])
		# input-resources propagate inwards
		var in_ring_n = ring.ring_number + 1 if Global.data[input_content[0]]["mode"] == "-" else ring.ring_number - 1
		if in_ring_n != Global.rings: # If not trying to insert from outside the outermost ring
			for l in ring.get_parent().get_child(in_ring_n).get_lanes():
				if l.lane_content != null and l.lane_content == input_content[0]:
					if not input_lanes[0].has(l):
						input_lanes[0].append(l)
						print("The ",name," will now import ",input_content[0]," from ",l," (total of ",input_lanes[0].size()," sources)")
						something_changed = true
	# Output
	var out_ring_n = ring.ring_number - 1 if Global.data[output_content]["mode"] == "-" else ring.ring_number + 1
	if out_ring_n == Global.rings :
		if output_lane == null and ship != null and is_instance_valid(ship): # Setup output to ship
			output_lane = ship
			print("The ",name," will now export ",output_content," to the ship ",ship)
			# Note: this is a self-contained operation, so something_changed = false
	elif output_storage > 0: 	# Only link the output if we have something to output...
		var out_ring = ring.get_parent().get_child(out_ring_n)
		var out_lane_id = out_ring.get_free_or_existing_lane(output_content)
		if out_lane_id != -1:
			var the_out_lane = out_ring.get_lane(out_lane_id)
			if output_lane != the_out_lane:
				output_lane = the_out_lane
				the_out_lane.register_resource(output_content, self)
				print("The ",name," will now export ",output_content," to ",the_out_lane)
				something_changed = true
	check_process()
	if something_changed:
		something_changed_node.something_changed()

func check_process():
	# Do we have all inputs and outputs?
	var satisfy_all : bool = true
	if output_lane == null:
		satisfy_all = false
	for il in input_lanes:
		if il.size() == 0:
			satisfy_all = false
	if satisfy_all:
		set_physics_process(true)
		return
	# OK - what about inputs, are there input lanes which are not yet full?
	var can_gather_inputs : bool = false
	if mode == Global.BUILDING_FACTORY:
		for i in range(input_lanes.size()):
			if input_lanes[i].size() > 0 and input_storage[i] < Global.MAX_STORAGE:
				can_gather_inputs = true
				break
	else: # Inserters/extracters only make use of output_storage
		if input_lanes.size() and input_lanes[0].size() > 0 and output_storage < Global.MAX_STORAGE:
			can_gather_inputs = true
	if can_gather_inputs:
		set_physics_process(true)
		return
	# OK - but do we still have outputs to send?
	var can_send_outputs : bool = false
	if output_storage > 0 and output_lane != null:
		can_send_outputs = true
	if can_send_outputs:
		set_physics_process(true)
		return
	# Deactivate until there is a change in the lane situation
	set_physics_process(false)
	
func _physics_process(_delta):
	if mode == Global.BUILDING_EXTRACTOR:
		# Inputs
		if output_storage < Global.MAX_STORAGE:
			for l in input_lanes[0]:
				l.try_capture(angle_back + global_rotation, self, Global.OUTWARDS)
		# Output
		if output_storage > 0 and output_lane != null and is_instance_valid(output_lane):
			var accepted = output_lane.try_send(global_rotation, Global.OUTWARDS)
			if accepted:
				output_storage -= 1
	elif mode == Global.BUILDING_INSERTER:
		# Inputs
		if output_storage < Global.MAX_STORAGE:
			for l in input_lanes[0]:
				l.try_capture(angle_front + global_rotation, self, Global.INWARDS)
		# Output
		if output_storage > 0 and output_lane != null:
			var accepted = output_lane.try_send(global_rotation, Global.INWARDS)
			if accepted:
				output_storage -= 1
	elif mode == Global.BUILDING_FACTORY:
		# Inputs
		for i in range(input_lanes.size()):
			if input_storage[i] < Global.MAX_STORAGE:
				for j in range(input_lanes[i].size()):
					# Factories capture from ABOVE, 1 or two rings
					var lane = input_lanes[i][j]
					lane.try_capture(angle_front + global_rotation, self, Global.INWARDS, input_lanes_distance[i][j])
		# Outputs
		if output_storage > 0 and output_lane != null:
			var direction : int = Global.INWARDS if Global.data[output_content]["mode"] == "-" else Global.OUTWARDS
			var accepted : bool = output_lane.try_send(global_rotation, direction)
			if accepted:
				output_storage -= 1

# Called asynchronously when try_capture succedes 
func add_item(var lane : MultiMeshInstance2D):
	if mode != Global.BUILDING_FACTORY:
		output_storage += 1
		# If this is the first thing we have had to output - then we may need to link our output lane
		if output_storage == 1 and output_lane == null:
			lane_system_changed()
	else: # mode == BUILDING_FACTORY
		for i in range(input_lanes.size()):
			if lane in input_lanes[i]:
				input_storage[i] += 1
				check_factory_production()
				break
				
func check_factory_production():
	if $Timer.get_time_left() > 0:
		return # Timer is already running
	for i in range(input_storage.size()):
		if input_storage[i] < input_factory_required[i]:
			return
	# Make new item
	for i in range(input_storage.size()):
		input_storage[i] -= input_factory_required[i]
	$Timer.start()
	
func _on_Timer_timeout():
	output_storage += output_amount
	if output_storage == output_amount and output_lane == null:
		lane_system_changed()
	check_factory_production()
