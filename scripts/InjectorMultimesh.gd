extends MultiMeshInstance2D

const WIDTH := 512.0
const EXTRA_MARGIN := 256.0

export(String) var set_resource = "None"
export(float) var set_period = 1.0

export(int) var n
export(float) var linear_velocity
export(float) var radius
export(int) var lane
export(NodePath) var ring = ""
export(bool) var placed = false

onready var outlines : Button = get_tree().get_root().find_node("Outlines", true, false)
onready var injector_button = get_tree().get_root().find_node("InjectorButton" + String(int(get_parent().name)), true, false)
onready var guide_lines : Node2D = get_parent().get_node("InjectorLines")
onready var blip_a : AudioStreamPlayer = Sfx.get_node("BlipA")

func serialise() -> Dictionary:
	var d = {}
	d["x"] = transform.origin.x
	d["resource"] = set_resource
	d["period"] = set_period
	d["n"] = n
	d["linear_velocity"] = linear_velocity
	d["radius"] = radius
	d["lane"] = lane
	d["ring"] = ring
	d["placed"] = placed
	return d
	
func deserialise(var d : Dictionary):
	transform.origin.x = d["x"]
	set_resource = d["resource"]
	set_period = d["period"]
	n = d["n"]
	linear_velocity = d["linear_velocity"]
	radius = d["radius"]
	lane = d["lane"]
	ring = d["ring"]
	placed = d["placed"]
	#
	set_properties_internal()
	# We have already deseralised the ring, so can properly reg the injector
	if ring != "":
		get_node(ring).register_resource(lane, set_resource, self)
		update_internal()
	
func _ready():
	n = 0
	multimesh = MultiMesh.new()
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	multimesh.mesh = QuadMesh.new()
	multimesh.mesh.set_size(Vector2(Global.GEM_SIZE,Global.GEM_SIZE))
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	update_resource(set_resource, set_period)
	
func update_resource(var res, var period):
	if placed and res != set_resource:
		# Cannot modify the resorce of a live lane, only the period. Must Remove the lane first"
		lane_cleared(null)
	set_resource = res
	set_period = period
	if set_resource == "":
		print("ERROR: Injector ",name," has no resource!")
	set_properties_internal()
	update_internal()

# Called by update_resource or deserialise()	
func set_properties_internal():
	modulate = Global.data[set_resource]["color"]
	texture = load("res://images/gems/gem_"+String(Global.data[set_resource]["shape"])+".png")
	normal_map = load("res://images/gems/gem_"+String(Global.data[set_resource]["shape"])+"_n.png")
	var per_sec : float = 1.0 / set_period
	injector_button.text = String(stepify(per_sec,0.5)) + "/" + tr("ui_s")
	injector_button.icon = Global.data[set_resource]["texture"]
	injector_button.visible = (set_resource != "None")
	if placed:
		injector_button.pressed = false
		injector_button.disabled = true
	else:
		injector_button.disabled = false
	
# Called when we place a lane, or the fundamental properties of an
# existing lane change and need updating
func update_internal():
	if ring == "": # Invalid
		return
	linear_velocity = get_node(ring).angular_velocity * radius
	var total_length := WIDTH + EXTRA_MARGIN
	n = round( (total_length/linear_velocity) / set_period ) 
	multimesh.instance_count = n
	for i in range(multimesh.instance_count):
		var offset = i * (linear_velocity * set_period);
		var orig := Vector2(-offset, -radius)
		var t := Transform2D(Vector2.RIGHT, Vector2.DOWN, orig)
		multimesh.set_instance_transform_2d(i, t)
		
func hint_resource(var attached_ring : Node2D, var ring_lane : int):
	if ring_lane == -1: # Invalid - no room
		ring = ""
		return
	radius = attached_ring.radius_array[ring_lane]
	lane = ring_lane
	ring = attached_ring.get_path()
	guide_lines.update()
	guide_lines.visible = true if outlines.pressed else false
	
	
func stop_hint_resource():
	if not placed:
		ring = ""
		visible = false
		guide_lines.visible = false

func setup_resource_at_hint():
	if ring == "": # Invalid
		return
	get_node(ring).register_resource(lane, set_resource, self)
	placed = true
	update_internal()
	transform.origin.x = -WIDTH
	guide_lines.update()
	guide_lines.visible = true if outlines.pressed else false
	visible = true
	# Disable my button
	Global.last_pressed = null
	injector_button.pressed = false
	injector_button.disabled = true
	# Propagate the change
	$"/root/Game/SomethingChanged".something_changed()
	
# Called when a lane rejects the input
func lane_cleared(var _lane):
	# Find my button and enable it
	injector_button.disabled = false
	Global.last_pressed = null
	multimesh.instance_count = 0
	placed = false
	stop_hint_resource()
	
func _physics_process(delta):
	if not placed:
		return
	transform.origin.x += delta * linear_velocity
	if transform.origin.x > 0:
		transform.origin.x -= linear_velocity * set_period
		var r = get_node(ring) if has_node(ring) else null
		if r != null and is_instance_valid(r):
			if r.add_to_ring(1.5 * PI, lane): # Always add new elements at the top
				blip_a.play()
