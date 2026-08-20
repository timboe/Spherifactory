extends MultiMeshInstance2D

var is_input : bool
var input_index : int
var resource : String
var factory_process : Node2D
var lane_process = null

func _ready():
	multimesh = MultiMesh.new()
	multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_NONE
	multimesh.mesh = QuadMesh.new()
	multimesh.mesh.set_size(Vector2(Global.GEM_SIZE,Global.GEM_SIZE))
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.instance_count = Global.MAX_STORAGE
	var vertical_break := int(floor(sqrt(Global.MAX_STORAGE)))
	for i in range(multimesh.instance_count):
		var orig := Vector2(10 * (i % vertical_break), 10 * floor(i/vertical_break))
		var t := Transform2D(Vector2.RIGHT, Vector2.DOWN, orig)
		multimesh.set_instance_transform_2d(i, t)

func reset():
	factory_process = null
	lane_process = null
	multimesh.visible_instance_count = 0

func update_visible():
	if lane_process != null:
		return update_visible_lane()
	###
	if factory_process == null:
		return
	if not is_instance_valid(factory_process):
		reset()
		return
	if "deleted" in factory_process.name:
		reset()
		return
	if factory_process.name != "Ship" and factory_process.mode == Global.BUILDING_UNSET:
		reset()
		return
	if is_input:
		multimesh.visible_instance_count = factory_process.input_storage[input_index]
	else:
		multimesh.visible_instance_count = factory_process.output_storage

func update_visible_lane():
	multimesh.visible_instance_count = clamp(lane_process.items_in_lane, 0, Global.MAX_STORAGE)

func set_resource(var _resource : String, var _factory_process, var _is_input : bool = false, var _index : bool = 0):
	#print("called set_resource with resource=",_resource," factory_process=",_factory_process," _is_input=",_is_input," _index=",_index)
	is_input = _is_input
	input_index = _index
	resource = _resource
	factory_process = _factory_process
	modulate = Global.data[resource]["color"]
	texture = load("res://images/gems/gem_"+String(Global.data[resource]["shape"])+".png")
	normal_map = load("res://images/gems/gem_"+String(Global.data[resource]["shape"])+"_n.png")
	update_visible()
	
func set_lane_resource(var _lane):
	if _lane == null or _lane.lane_content == null:
		reset()
		return
	lane_process = _lane
	resource = _lane.lane_content
	modulate = Global.data[resource]["color"]
	texture = load("res://images/"+Global.data[resource]["shape"]+".png")
	normal_map = load("res://images/"+Global.data[resource]["shape"]+"_n.png")
	update_visible()
