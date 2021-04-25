extends MultiMeshInstance2D
tool

const WIDTH := 512.0
const EXTRA_MARGIN := 256.0

export(String) var set_resource = ""
export(float) var set_period = 1.0

export(int) var n
export(float) var linear_velocity
export(float) var radius
export(int) var lane
export(NodePath) var ring = ""
export(bool) var placed = false

onready var injector_button = get_tree().get_root().find_node("InjectorButton" + String(int(get_parent().name)), true, false)

func _ready():
	n = 0
	multimesh = MultiMesh.new()
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	multimesh.mesh = QuadMesh.new()
	multimesh.mesh.set_size(Vector2(10,10))
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	if set_resource == "":
		print("ERROR: Injector ",name," has no resource!")
	modulate = Global.data[set_resource]["color"]
	texture = load("res://images/"+Global.data[set_resource]["shape"]+".png")
	var per_sec : float = 1.0 / set_period
	injector_button.text = String(per_sec) + "/s"

func hint_resource(var attached_ring : Node2D, var ring_lane : int):
	if ring_lane == -1: # Invalid - no room
		ring = ""
		return
	radius = attached_ring.radius_array[ring_lane]
	lane = ring_lane
	ring = attached_ring.get_path()
	get_parent().update()
	get_parent().visible = true
	
func stop_hint_resource():
	if not placed:
		ring = ""
		get_parent().visible = false

func setup_resource_at_hint():
	if ring == "": # Invalid
		return
	get_node(ring).register_resource(lane, set_resource, self)
	placed = true
	linear_velocity = get_node(ring).angular_velocity * radius
	var total_length := WIDTH + EXTRA_MARGIN
	n = round( (total_length/linear_velocity) / set_period ) 
	multimesh.instance_count = n
	for i in range(multimesh.instance_count):
		var offset = i * (linear_velocity * set_period);
		var orig := Vector2(-offset, -radius)
		var t := Transform2D(Vector2.RIGHT, Vector2.DOWN, orig)
		multimesh.set_instance_transform_2d(i, t)
	transform.origin.x = -WIDTH
	get_parent().update()
	get_parent().visible = true
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
		get_node(ring).add_to_ring(1.5 * PI, lane) # Always add new elements at the top
