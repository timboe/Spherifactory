extends Node2D

const POINTS := 32

onready var id = get_tree().get_root().find_node("InfoDialog", true, false) 
onready var cam = get_tree().get_root().find_node("Camera2D", true, false) 
onready var ring = find_parent("Ring*")
onready var rotation_node = find_parent("Rotation")
onready var camera_2d := get_tree().get_root().find_node("Camera2D", true, false)

export(float) var inner_radius
export(float) var outer_radius
export(float) var span_radians

export(float) var factory_angle_start
export(float) var factory_angle_end

export(PoolColorArray) var factory_color
export(Color) var factory_outline_color
export(bool) var colliding

export(int) var mode = Global.BUILDING_UNSET
export(String) var recipy = null
export(String) var descriptive_name = ""

var points_vec = PoolVector2Array()

func serialise() -> Dictionary:
	var d : Dictionary = $FactoryProcess.serialise()
	d["name"] = name
	d["parent_ring"] = ring.get_path()
	#
	d["global_rotation"] = global_rotation
	#
	d["inner_radius"] = inner_radius
	d["outer_radius"] = outer_radius
	d["span_radians"] = span_radians
	d["factory_angle_start"] = factory_angle_start
	d["factory_angle_end"] = factory_angle_end
	d["factory_color"] = factory_color[0].to_html()
	d["factory_outline_color"] = factory_outline_color.to_html()
	d["mode"] = mode
	d["recipy"] = recipy
	d["descriptive_name"] = descriptive_name
	return d

func deserialise(var d : Dictionary):
	global_rotation = d["global_rotation"]
	#
	inner_radius = d["inner_radius"]
	outer_radius = d["outer_radius"]
	span_radians = d["span_radians"] 
	factory_angle_start = d["factory_angle_start"]
	factory_angle_end = d["factory_angle_end"]
	factory_color[0] = Color(d["factory_color"])
	factory_outline_color = Color(d["factory_outline_color"])
	mode = d["mode"]
	recipy = d["recipy"]
	descriptive_name = d["descriptive_name"]
	if recipy != null:
		$Label.text = recipy + Global.data[recipy]["mode"]
	update()
	$FactoryProcess.deserialise(d)

func _ready():
	reset()
	set_process(false)

# Process handles factory collision when placing
func _process(var _delta):
	if ring == null or not is_instance_valid(ring):
		return
	factory_angle_start = (global_rotation - span_radians/2.0) - rotation_node.rotation
	factory_angle_end = (global_rotation + span_radians/2.0) - rotation_node.rotation
	# Jus checking the innermost lane is fine
	var placeable = ring.get_lane(0).get_range_fillable(factory_angle_start, factory_angle_end)
	if !placeable != colliding:
		colliding = !placeable
		if colliding:
			factory_color = PoolColorArray([Color(0.5, 0.0, 0.17, 1.0)])
		else:
			factory_color = PoolColorArray([Color(0.6, 0.6, 0.6, 1.0)])
		update()

func add_arc(var points : int,
  var start : float, var end : float,
   var centre : Vector2, var radius : float):
	var span = end - start
	for i in range(points + 1):
		var angle_point = ((i * span) / POINTS) + start
		points_vec.push_back(centre + (Vector2(cos(angle_point), sin(angle_point)) * radius))

func _draw():
	#mode = BUILDING_EXTRACTOR
	var radius_mod : float = (outer_radius - inner_radius) * Global.INSERTER_RADIUS_MOD
	var span_mod = span_radians * Global.INSERTER_RADIUS_MOD
	points_vec.resize(0)
	###
	if mode == Global.BUILDING_INSERTER:
		points_vec.push_back(Vector2(cos(-span_radians/2.0), sin(-span_radians/2.0)) * (inner_radius + radius_mod))
		points_vec.push_back(Vector2(inner_radius - radius_mod, 0))
		points_vec.push_back(Vector2(cos(+span_radians/2.0), sin(+span_radians/2.0)) * (inner_radius + radius_mod))
	elif mode == Global.BUILDING_FACTORY and Global.data[recipy]["mode"] == "-":
		add_arc(POINTS, -span_radians/2.0, -span_mod, Vector2.ZERO, inner_radius)
		points_vec.push_back(Vector2(inner_radius - radius_mod, 0))
		add_arc(POINTS, +span_mod, +span_radians/2.0, Vector2.ZERO, inner_radius)
	else:
		add_arc(POINTS, -span_radians/2.0, +span_radians/2.0, Vector2.ZERO, inner_radius)
	###
	if mode == Global.BUILDING_FACTORY:
		var mod_r = inner_radius + (outer_radius - inner_radius)/2.0
		var mod_angle = span_radians/2.0 + span_radians * Global.INSERTER_RADIUS_MOD
		points_vec.push_back(Vector2(cos(mod_angle), sin(mod_angle)) * mod_r)
	###
	if mode == Global.BUILDING_EXTRACTOR:
		points_vec.push_back(Vector2(cos(+span_radians/2.0), sin(+span_radians/2.0)) * (outer_radius - radius_mod))
		points_vec.push_back(Vector2(outer_radius + radius_mod, 0))
		points_vec.push_back(Vector2(cos(-span_radians/2.0), sin(-span_radians/2.0)) * (outer_radius - radius_mod))
	elif mode == Global.BUILDING_FACTORY and Global.data[recipy]["mode"] == "+":
		add_arc(POINTS, +span_radians/2.0, +span_mod, Vector2.ZERO, outer_radius)
		points_vec.push_back(Vector2(outer_radius + radius_mod, 0))
		add_arc(POINTS, -span_mod, -span_radians/2.0, Vector2.ZERO, outer_radius)
	else:
		add_arc(POINTS, +span_radians/2.0, -span_radians/2.0, Vector2.ZERO, outer_radius)
	###
	if mode == Global.BUILDING_FACTORY:
		var mod_r = inner_radius + (outer_radius - inner_radius)/2.0
		var mod_angle = -span_radians/2.0 - span_radians * Global.INSERTER_RADIUS_MOD
		points_vec.push_back(Vector2(cos(mod_angle), sin(mod_angle)) * mod_r)
	###
	points_vec.push_back(points_vec[0])
	###
	draw_polygon(points_vec, factory_color, PoolVector2Array(), null, null, true)
	draw_polyline(points_vec, factory_outline_color, 2.0, true)
	$FactoryProcess.angle_back = -span_radians/2.0
	$FactoryProcess.angle_front = span_radians/2.0
	#
	$TextureButton.rect_position.x = inner_radius
	$Label.rect_position.x = inner_radius + 21 # Magic number from size of rotated text box
	
func configure_building():
	if Global.last_satelite_type == null:
		return
	if mode != Global.BUILDING_UNSET:
		reset()
	mode = Global.last_satelite_type
	recipy = Global.last_satelite_recipe
	$FactoryProcess.configure(mode, recipy)
	factory_outline_color = Global.data[recipy]["color"]
	factory_color[0] = Global.lighten(factory_outline_color)
	$Label.text = recipy + Global.data[recipy]["mode"]
	update()
	set_descriptive_name()
	check_add_remove_ship()
	
func get_process_node():
	return $FactoryProcess

func reset():
	mode = Global.BUILDING_UNSET
	recipy = null
	factory_outline_color = Color(0.8, 0.8, 0.8)
	factory_color = PoolColorArray([Color(0.6, 0.6, 0.6, 1.0)])
	$FactoryProcess.reset()
	$Label.text = ""
	update()
	set_descriptive_name()

func remove():
	$FactoryProcess.reset()
	$FactoryProcess.name = "deleted"
	for l in ring.get_lanes():
		l.set_range_fillable(factory_angle_start, factory_angle_end, true)
	name = "deleted"
	queue_free()
	if camera_2d.follow_target == self:
		camera_2d.stop_follow()

func lane_cleared(var lane_or_ship : Node2D):
	$FactoryProcess.lane_cleared(lane_or_ship)
	
func set_descriptive_name():
	descriptive_name = "#" + String(name.to_int()) + ": "
	if mode == Global.BUILDING_UNSET:
		descriptive_name += tr("ui_unasigned_satellite")
	else:
		descriptive_name += recipy
		descriptive_name += Global.data[recipy]["mode"]
	if mode == Global.BUILDING_FACTORY:
		descriptive_name += " " + tr("ui_factory")
	elif mode == Global.BUILDING_INSERTER:
		descriptive_name += " " + tr("ui_inserter")
	elif mode == Global.BUILDING_EXTRACTOR:
		descriptive_name += " " + tr("ui_extractor") 

func setup_resource(var i_radius : float, var o_radius : float, var _span : float):
	inner_radius = i_radius
	outer_radius = o_radius
	span_radians = _span
	factory_color = PoolColorArray([Color(0.6, 0.6, 0.6, 1.0)])
	colliding = false
	update()
	
func check_add_remove_ship():
	if ring == null or not is_instance_valid(ring):
		return
	if $FactoryProcess.ship == null and mode == Global.BUILDING_EXTRACTOR and ring.ring_number + 1 == Global.rings:
		_on_NewShip_timeout()
	elif ring.ring_number + 1 != Global.rings:
		print("rmove any ships from ",ring.ring_number + 1," (note +1) which is not ", Global.rings)
		$FactoryProcess.remove_any_ship()

func _on_NewShip_timeout():
	if ring.ring_number + 1 != Global.rings:
		print("_on_NewShip_timeout cancelled due to not being outer ring")
		return
	print("New ship")
	var sr = ring.get_node("ShipRotationTemplate").duplicate(DUPLICATE_SCRIPTS|DUPLICATE_GROUPS|DUPLICATE_SIGNALS)
	sr.name = "ShipRotation1"
	ring.add_child(sr, true)
	sr.set_owner(get_tree().get_root())
	sr.global_rotation = self.global_rotation
	$FactoryProcess.ship = sr.get_child(0)
	$FactoryProcess.ship.configure_ship(recipy, self)
	id.update_diag()

func _on_TextureButton_gui_input(event):
	if event is InputEventMouseButton and not event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				id.show_building_diag(self)
				return
			BUTTON_RIGHT:
				configure_building()
				return
	cam._unhandled_input(event)
