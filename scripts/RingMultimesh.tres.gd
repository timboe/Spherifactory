extends MultiMeshInstance2D
tool

const DISABLE := 100.0
const INJECT_VELOCITY := 128.0

enum {OUTWARDS, INWARDS}

export(float) var radians_per_slot
export(float) var radius
export(String) var lane_content = null
export(bool) var source = false
export(bool) var sink = false
var lane_provinance : Array = [] # Note: NOT exported, becomes shared!

var ring_radius = load("res://scripts/RingSystem.gd").new().RING_RADIUS
var out_flight = []
var in_flight = []

# Called when the node enters the scene tree for the first time.
func _ready():
	multimesh = MultiMesh.new()
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_8BIT
	multimesh.mesh = QuadMesh.new()
	multimesh.mesh.set_size(Vector2(10,10))
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
	
func add_to_ring(var angle : float):
	var slot : int = round(wrap_a(angle) / radians_per_slot)
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
	
func set_range_fillable(var start : float, var end : float, var fillable : bool):
	var slot_start : int = wrap_i(round(wrap_a(start) / radians_per_slot))
	var slot_end : int = wrap_i(round(wrap_a(end) / radians_per_slot))
	while true:
		set_slot_fillable(slot_start, fillable)
		slot_start = wrap_i(slot_start + 1)
		if (slot_start == slot_end): break

func set_as_source_lane():
	source = true
	for i in multimesh.instance_count:
		set_slot_filled(i, true, true)

func register_resource(var new_resource : String, var provinance : Node):
	if lane_content != null:
		print("ERROR in ",name," of ", get_parent().get_parent().get_parent().name, " trying to reg ",new_resource," into lane containing ",lane_content)
		return
	lane_content = new_resource
	lane_provinance.append(provinance)
	modulate = Global.data[lane_content]["color"]
	
func deregister_resource():
	if lane_content == null:
		print("ERROR trying to dereg in lane ",name," which isn'rt registered")
		return
	lane_content = null
	for p in lane_provinance:
		p.lane_cleared(self)
	lane_provinance.clear()
	for i in multimesh.instance_count:
		set_slot_filled(i, false, true)

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

func try_capture(var angle : float, var caller : Node, var direction : int):
	var i : int = wrap_i(round(wrap_a(angle - global_rotation) / radians_per_slot))
	var c : Color = multimesh.get_instance_custom_data(i)
	if not (c.r == 1 and c.g == 1): #same as get_slot_filled_and_captureable
		return
	c.g = 0 # Not capturable (caus' it's now captured)
	multimesh.set_instance_custom_data(i, c)
	var moving = {}
	moving["i"] = i
	moving["call"] = caller
	moving["dir"] = direction
	moving["offset"] = (2.0 * PI) * 1.0/float(multimesh.instance_count) * float(i)
	moving["radius"] = radius
	moving["target"] = radius + ring_radius if direction == OUTWARDS else radius - ring_radius
	out_flight.append(moving)
	
func try_send(var angle : float, var direction : int) -> bool:
	var i : int = wrap_i(round(wrap_a(angle - global_rotation) / radians_per_slot))
	var c : Color = multimesh.get_instance_custom_data(i)
	if not (c.r == 0 and c.b == 1): #get_slot_empty_and_fillable
		return false
	c.r = 1 # Now filled
	c.b = 0 # Hence not fillable
	multimesh.set_instance_custom_data(i, c)
	var t : Transform2D = multimesh.get_instance_transform_2d(i)
	t.origin /= DISABLE # Make visible again
	multimesh.set_instance_transform_2d(i, t)
	var moving = {}
	moving["i"] = i
	moving["dir"] = direction
	moving["offset"] = (2.0 * PI) * 1.0/float(multimesh.instance_count) * float(i)
	moving["radius"] = radius - ring_radius if direction == OUTWARDS else radius + ring_radius
	moving["target"] = radius
	in_flight.append(moving)
	return true
	
func _physics_process(var delta):
	# Items which are flinging out (to below or above)
	for arr_i in range(out_flight.size()-1, -1, -1):
		var d = out_flight[arr_i]
		var i : int = d["i"]
		var dir : int = d["dir"]
		var t : Transform2D = multimesh.get_instance_transform_2d(i)
		d["radius"] += delta * INJECT_VELOCITY if dir == OUTWARDS else -delta * INJECT_VELOCITY
		var finished : bool  = false 
		if (dir == OUTWARDS and d["radius"] >= d["target"]) or (dir == INWARDS and d["radius"] <= d["target"]):
			finished = true
			d["radius"] = radius
		var offset = d["offset"]
		t.origin = Vector2(cos(offset), sin(offset)) * d["radius"]
		if finished: # Set empty and remove from dict
			if source: # Source rings never run out
				multimesh.set_instance_custom_data(i, Color(1,1,1,0))
			else:
				t.origin *= DISABLE
				multimesh.set_instance_custom_data(i, Color(0,1,1,0))
			d["call"].add_item(self)
			out_flight.remove(arr_i)
		multimesh.set_instance_transform_2d(i, t)
	# Items which are cascading in (from above or below)
	for arr_i in range(in_flight.size()-1, -1, -1):
		var d = in_flight[arr_i]
		var i : int = d["i"]
		var dir : int = d["dir"]
		var t : Transform2D = multimesh.get_instance_transform_2d(i)
		d["radius"] += delta * INJECT_VELOCITY if dir == OUTWARDS else -delta * INJECT_VELOCITY
		var finished : bool  = false 
		if (dir == OUTWARDS and d["radius"] >= d["target"]) or (dir == INWARDS and d["radius"] <= d["target"]):
			finished = true
			d["radius"] = radius
		var offset = d["offset"]
		t.origin = Vector2(cos(offset), sin(offset)) * d["radius"]
		if finished: # Set empty and remove from dict
			if sink: # Sink consumes
				multimesh.set_instance_custom_data(i, Color(0,1,1,0))
			else:
				multimesh.set_instance_custom_data(i, Color(1,1,1,0))
			in_flight.remove(arr_i)
		multimesh.set_instance_transform_2d(i, t)



func set_slot_filled(var i : int, var filled : bool, var capturable : bool):
	if source:
		filled = true
	if not bool(get_slot_filled(i)) == filled:
		var t : Transform2D = multimesh.get_instance_transform_2d(i)
		if filled:
			t.origin /= DISABLE
		else:
			t.origin *= DISABLE
		multimesh.set_instance_transform_2d(i, t)
	var c : Color = multimesh.get_instance_custom_data(i)
	c.r = filled
	c.g = capturable
	multimesh.set_instance_custom_data(i, c)
	
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
		var t := Transform2D(Vector2.RIGHT, Vector2.DOWN, p)
		t.origin *= DISABLE
		# All nodes start off as filled = 0, capturable = 1, fillable = 1
		multimesh.set_instance_transform_2d(i, t)
		multimesh.set_instance_custom_data(i, Color(0,1,1,0))
