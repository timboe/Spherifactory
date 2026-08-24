extends MultiMeshInstance2D

const DISABLE := 100.0
const INJECT_VELOCITY := 128.0
const RING_RADIUS := 40 # Matches RingSystem.RING_RADIUS

export(float) var radians_per_slot
export(float) var radius
export(String) var lane_content = null
export(bool) var source = false
export(bool) var sink = false
export(bool) var forbid_send = false
var lane_provinance : Array = [] # Note: NOT exported, becomes shared!
var laneswap_target : Array = [null] 
var items_in_lane := 0

var in_flight = []

func serialise() -> Dictionary:
	var d := {}
	d["radians_per_slot"] = radians_per_slot
	d["radius"] = radius
	d["lane_content"] = lane_content
	d["source"] = source
	d["sink"] = sink
	d["forbid_send"] = forbid_send
	d["lane_provinance"] = lane_provinance
	d["items_in_lane"] = items_in_lane
	d["laneswap_target"] = laneswap_target[0].get_path() if laneswap_target[0] != null else null
	#
	var content = []
	for i in range(multimesh.instance_count):
		var flags : int = 0
		var c = multimesh.get_instance_custom_data(i)
		if c.r: flags |= 1
		if c.g: flags |= 2
		if c.b: flags |= 4
		if c.a: flags |= 8
		content.append(flags)
	d["multimesh_custom_data"] = content
	#
	# in flight?
	return d
	
func deserialise(var d : Dictionary):
	radians_per_slot = d["radians_per_slot"]
	radius = d["radius"]
	lane_content = d["lane_content"]
	source = d["source"]
	sink = d["sink"]
	forbid_send = d["forbid_send"]
	lane_provinance = d["lane_provinance"]
	items_in_lane = d["items_in_lane"]
	laneswap_target[0] = null if d["laneswap_target"] == null else get_node(d["laneswap_target"])
	if lane_content != null:
		register_resource(lane_content, null)
	#
	# Don't actually currently need to re-setup the multimesh. Setup here is static.
	#
	var content : Array = d["multimesh_custom_data"]
	for i in range(multimesh.instance_count):
		if i >= content.size():
			break
		var flags : int = content[i]
		var c = Color(0,0,0,0)
		c.r = flags & 1 
		c.g = flags & 2
		c.b = flags & 4
		c.a = flags & 8
		# While we are not saving in-flight data, we have to overwrite the capturable and fillable data
		if c.r == 0: # Not filled
			c.g = 0 # capturable
			c.b = 1 # fillable
		else:
			c.g = 1 # capturable
			c.b = 0 # fillable
			var t : Transform2D = multimesh.get_instance_transform_2d(i)
			t.origin /= DISABLE
			multimesh.set_instance_transform_2d(i, t)
		multimesh.set_instance_custom_data(i, c)
	#
	# in flight?

# Called when the node enters the scene tree for the first time.
func _ready():
	multimesh = MultiMesh.new()
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_8BIT
	multimesh.mesh = QuadMesh.new()
	multimesh.mesh.set_size(Vector2(Global.GEM_SIZE,Global.GEM_SIZE))
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	
func wrap_i(var i : int):
	while i < 0:
		i += multimesh.instance_count
	while i >= multimesh.instance_count:
		i -= multimesh.instance_count
	return i
	
func wrap_a(var f : float):
	while f < 0:
		f += PI*2
	while f >= PI*2:
		f -= PI*2
	return f
	
func get_slot(var angle : float) -> int:
	return int(round(wrap_a(angle) / radians_per_slot))
	
func get_slot_from_global_angle(var angle : float) -> int:
	return wrap_i(round(wrap_a(angle - global_rotation) / radians_per_slot))
		
func get_angle(var slot : int) -> float:
	return (2.0 * PI) * 1.0/float(multimesh.instance_count) * float(slot)
	
func get_ring() -> Node2D:
	return find_parent("Ring*") as Node2D
	
func add_to_ring(var angle : float) -> bool:
	var slot : int = get_slot(angle)
	# Try and fill up ahead
	for i in range(slot, slot+3):
		var i_wrap = wrap_i(i)
		if get_slot_empty_and_fillable(i_wrap):
			set_slot_filled(i_wrap, true, true)
			return true
	# Or, if we cannot - then try and fill up behind
	for i in range(slot-1, slot-4, -1):
		var i_wrap = wrap_i(i)
		if get_slot_empty_and_fillable(i_wrap):
			set_slot_filled(i_wrap, true, true)
			return true
	return false

func set_as_source_lane():
	source = true
	sink = false
	for i in multimesh.instance_count:
		set_slot_filled(i, true, true)

func set_as_sink_lane():
	sink = true
	source = false
	for i in multimesh.instance_count:
		set_slot_filled(i, false, true)
		
func set_laneswap(var other_lane : MultiMeshInstance2D):
	set_as_sink_lane()
	laneswap_target[0] = other_lane

func register_resource(var new_resource : String, var provinance : Node):
	if lane_content != null and new_resource != lane_content:
		print("ERROR in ",name," of ", get_parent().get_parent().get_parent().name, " trying to reg ",new_resource," into lane containing ",lane_content)
		return
	# If we are a sink, we can accept many different inputs
	if not sink:
		lane_content = new_resource
		modulate = Global.data[lane_content]["color"]
		texture = load("res://images/gems/gem_"+String(Global.data[lane_content]["shape"])+".png")
		normal_map = load("res://images/gems/gem_"+String(Global.data[lane_content]["shape"])+"_n.png")
	if provinance != null and not (provinance.get_path() in lane_provinance):
		lane_provinance.append(provinance.get_path())
	# Refresh the lane-content bars via the debounced SomethingChanged timer
	# (batched - a synchronous fan-out here is O(rings) per lane operation)
	$"/root/Game/SomethingChanged".something_changed()
	
func deregister_provider(var provider):
	var path = provider.get_path()
	if not path in lane_provinance:
		print("ERROR trying to dereg provider ",provider.name, " from lane ",name," which isn't registered")
		return
	lane_provinance.erase(path)
	provider.lane_cleared(self)
	
func deregister_resource():
	if lane_content == null:
		print("ERROR trying to dereg in lane ",name," which isn'rt registered")
		return
	lane_content = null
	laneswap_target[0] = null
	in_flight.clear()
	for p in lane_provinance:
		if has_node(p):
			var n = get_node(p)
			if n != null and is_instance_valid(n):
				n.lane_cleared(self)
	lane_provinance.clear()
	for i in multimesh.instance_count:
		set_slot_filled(i, false, true)
	# These calls handle things also which take from the lane
	for f in get_tree().get_nodes_in_group("FactoryGroup"):
		if is_instance_valid(f) and not f.is_queued_for_deletion():
			f.lane_cleared(self)

func get_slot_filled(var i : int) -> bool:
	return bool(multimesh.get_instance_custom_data(i).r)
	
func get_slot_capturable(var i : int) -> bool:
	return bool(multimesh.get_instance_custom_data(i).g)
	
func get_slot_fillable(var i : int) -> bool:
	return bool(multimesh.get_instance_custom_data(i).b)

func get_slot_filled_and_captureable(var i : int) -> bool:
	var c : Color = multimesh.get_instance_custom_data(i)
	return (c.r == 1 and c.g == 1)
	
func get_slot_empty_and_fillable(var i : int) -> bool:
	var c : Color = multimesh.get_instance_custom_data(i)
	return (c.r == 0 and c.b == 1)

func try_capture(var glob_angle : float, var caller : Node, var direction : int, var distance : int = 1):
	var i : int = get_slot_from_global_angle(glob_angle)
	var c : Color = multimesh.get_instance_custom_data(i)
	if not (c.r == 1 and c.g == 1): #same as get_slot_filled_and_captureable
		return
	c.g = 0 # Not capturable (caus' it's now captured)
	multimesh.set_instance_custom_data(i, c)
	var moving = {}
	moving["i"] = i
	moving["call"] = caller
	moving["dir"] = direction
	moving["offset"] = get_angle(i)
	moving["radius"] = radius
	moving["target"] = radius + (RING_RADIUS * distance) if direction == Global.OUTWARDS else radius - (RING_RADIUS * distance)
	in_flight.append(moving)
	
func try_send(var glob_angle : float, var direction : int) -> bool:
	var i : int = get_slot_from_global_angle(glob_angle)
	var c : Color = multimesh.get_instance_custom_data(i)
	if not (c.r == 0 and c.b == 1): #get_slot_empty_and_fillable
		return false
	c.r = 1 # Now filled
	c.b = 0 # Hence not fillable
	var new_radius = radius - RING_RADIUS if direction == Global.OUTWARDS else radius + RING_RADIUS
	var offset = (2.0 * PI) * 1.0/float(multimesh.instance_count) * float(i)
	multimesh.set_instance_custom_data(i, c)
	var t : Transform2D = multimesh.get_instance_transform_2d(i)
	t.origin /= DISABLE # Make visible again
	t.origin = Vector2(cos(offset), sin(offset)) * new_radius
	multimesh.set_instance_transform_2d(i, t)
	var moving = {}
	moving["i"] = i
	moving["dir"] = direction
	moving["offset"] = offset
	moving["radius"] = new_radius
	moving["target"] = radius
	in_flight.append(moving)
	return true
	
func _physics_process(var delta):
	for arr_i in range(in_flight.size()-1, -1, -1):
		var d = in_flight[arr_i]
		var i : int = d["i"]
		var dir : int = d["dir"]
		var t : Transform2D = multimesh.get_instance_transform_2d(i)
		d["radius"] += delta * INJECT_VELOCITY if dir == Global.OUTWARDS else -delta * INJECT_VELOCITY
		var finished : bool  = false 
		if (dir == Global.OUTWARDS and d["radius"] >= d["target"]) or (dir == Global.INWARDS and d["radius"] <= d["target"]):
			finished = true
			d["radius"] = radius
		var offset = d["offset"]
		t.origin = Vector2(cos(offset), sin(offset)) * d["radius"]
		if finished:
			if "call" in d: # Items which are flinging out (to below or above)
				if source: # Source rings never run out
					multimesh.set_instance_custom_data(i, Color(1,1,1,0))
				else:
					t.origin *= DISABLE
					items_in_lane -= 1
					multimesh.set_instance_custom_data(i, Color(0,1,1,0))
				var call = d["call"] 
				if call != null and is_instance_valid(call): # This might have been deleted in the time to move the item!
					call.add_item(self)
			else: # Items which are cascading in (from above or below)
				# Set empty and remove from dict
				if sink: # Sink consumes
					t.origin *= DISABLE
					multimesh.set_instance_custom_data(i, Color(0,1,1,0))
					if laneswap_target[0] != null:
						laneswap_target[0].set_slot_filled(i, true, true)
				else:
					multimesh.set_instance_custom_data(i, Color(1,1,1,0))
			in_flight.remove(arr_i)
		multimesh.set_instance_transform_2d(i, t)


func highlight(var i):
	set_slot_filled(i, true, true)
	var t : Transform2D = multimesh.get_instance_transform_2d(i)
	var offset = get_angle(i)
	t.origin = Vector2(cos(offset), sin(offset)) * (radius - 5)
	multimesh.set_instance_transform_2d(i, t)

func set_slot_filled(var i : int, var filled : bool, var capturable : bool):
	if laneswap_target[0] != null:
		laneswap_target[0].set_slot_filled(i, filled, capturable)
		return
	
	i = wrap_i(i)
	if source:
		filled = true
	if sink:
		filled = false
	if not bool(get_slot_filled(i)) == filled:
		var t : Transform2D = multimesh.get_instance_transform_2d(i)
		if filled:
			t.origin /= DISABLE
			items_in_lane += 1
		else:
			t.origin *= DISABLE
			items_in_lane -= 1
		multimesh.set_instance_transform_2d(i, t)
	var c : Color = multimesh.get_instance_custom_data(i)
	c.r = filled
	c.g = capturable
	multimesh.set_instance_custom_data(i, c)

func get_range_fillable(var start : float, var end : float) -> bool:
	var slot_start : int = wrap_i(round(wrap_a(start) / radians_per_slot))
	var slot_end : int = wrap_i(round(wrap_a(end) / radians_per_slot))
	while true:
		if not get_slot_fillable(slot_start):
			return false
		slot_start = wrap_i(slot_start + 1)
		if (slot_start == slot_end): break
	return true

func set_range_fillable(var start : float, var end : float, var fillable : bool):
	var slot_start : int = wrap_i(round(wrap_a(start) / radians_per_slot))
	var slot_end : int = wrap_i(round(wrap_a(end) / radians_per_slot))
	while true:
		set_slot_fillable(slot_start, fillable)
		slot_start = wrap_i(slot_start + 1)
		if (slot_start == slot_end): break

func set_slot_fillable(var i : int, var fillable : bool):
	var c : Color = multimesh.get_instance_custom_data(i)
	c.b = int(fillable)
	multimesh.set_instance_custom_data(i, c)
	if not fillable:
		set_slot_filled(i, false, true)

func setup_resource(var n : int, var _radius : float):
	radius = _radius
	multimesh.instance_count = n
	radians_per_slot = (2.0 * PI) / n
	for i in range(multimesh.instance_count):
		var offset = (2.0 * PI) * 1.0/float(multimesh.instance_count) * float(i)
		var p : Vector2 = Vector2(cos(offset), sin(offset)) * radius
		var t := Transform2D(Vector2.RIGHT, Vector2.DOWN, Vector2.ZERO)
		t = t.rotated(offset)
		t.origin = p * DISABLE
		# All nodes start off as filled = 0, capturable = 1, fillable = 1
		multimesh.set_instance_transform_2d(i, t)
		multimesh.set_instance_custom_data(i, Color(0,1,1,0))
