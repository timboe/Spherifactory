extends Node2D

const TWOPI := PI * 2.0
const SHIP_SIZE = 10.0
const SHIP_APPEAR_TIME := 1.0
const SHIP_DEPART_TIME := 10.0
const SHIP_DEPART_RADIUS := 1024.0

export(float) var base_radius
export(float) var radius

export(float) var inner_radius
export(float) var outer_radius
export(float) var span_radians

export(bool) var built = false
export(bool) var launch = false

export(int) var output_storage = 0
export(String) var recipe = ""
export(bool) var deposited = false

export(PoolColorArray) var ship_color
export(Color) var outline_color

export(NodePath) var factory = ""

var points_vec = PoolVector2Array()

onready var id : WindowDialog = get_tree().get_root().find_node("InfoDialog", true, false) 
onready var rule_changer : Node2D = get_tree().get_root().find_node("RuleChanger", true, false) 
onready var rocket : AudioStreamPlayer = get_node("Rocket")
onready var ring = find_parent("Ring*")
onready var something_changed_node = $"/root/Game/SomethingChanged"
onready var camera_2d := get_tree().get_root().find_node("Camera2D", true, false)

func serialise() -> Dictionary:
	var d := {}
	d["parent_ring"] = ring.get_path()
	#
	d["shiprotator_name"] = get_parent().name
	d["shiprotator_global_rotation"] = get_parent().global_rotation
	#
	d["inner_radius"] = inner_radius
	d["outer_radius"] = outer_radius
	d["span_radians"] = span_radians
	d["built"] = built
	d["launch"] = launch
	d["output_storage"] = output_storage
	d["recipe"] = recipe
	d["deposited"] = deposited
	d["ship_color"] = ship_color[0].to_html()
	d["outline_color"] = outline_color.to_html()
	d["factory"] = factory
	return d

func deserialise(var d : Dictionary):
	inner_radius = d["inner_radius"] 
	outer_radius = d["outer_radius"]
	span_radians = d["span_radians"]
	built = d["built"]
	launch = d["launch"]
	output_storage = d["output_storage"]
	recipe = d["recipe"]
	deposited = d.get("deposited", false)
	ship_color[0] = Color(d["ship_color"])
	outline_color = Color(d["outline_color"])
	factory = d["factory"]
	# Force bulding to finish
	if not built:
		appear_complete()
	update()
	set_physics_process(true)
	visible = true
	get_parent().visible = true
	# Add to factory
	var fac = get_node(factory)
	if fac == null:
		print("ERROR deserialising ship ",get_path()," was not able to find its factory at ",factory)
	else:
		fac.get_node("FactoryProcess").ship = self

func _ready():
	outline_color = Color(0.8, 0.8, 0.8, 1.0)
	ship_color = PoolColorArray([Color(0.6, 0.6, 0.6, 1.0)])
	built = false
	launch = false
	deposited = false
	rocket.volume_db = linear2db(Global.settings["sfx"] * 0.01)
	set_physics_process(false)

func _draw():
	var radius_mod : float = (outer_radius - inner_radius) * Global.INSERTER_RADIUS_MOD
	points_vec.resize(0)
	points_vec.push_back(Vector2(cos(+span_radians/2.0), sin(+span_radians/2.0)) * (outer_radius - radius_mod))
	points_vec.push_back(Vector2(outer_radius + radius_mod, 0))
	points_vec.push_back(Vector2(cos(-span_radians/2.0), sin(-span_radians/2.0)) * (outer_radius - radius_mod))
	#
	points_vec.push_back(Vector2(outer_radius + SHIP_SIZE * radius_mod, 0))
	#
	points_vec.push_back(points_vec[0])
	#
	draw_polygon(points_vec, ship_color, PoolVector2Array(), null, null, true)
	draw_polyline(points_vec, outline_color, 2.0, true)
	
func setup_resource(var _radius : float, var i_radius : float, var o_radius : float, var _span : float):
	inner_radius = i_radius
	outer_radius = o_radius
	base_radius = _radius
	radius = _radius
	span_radians = _span
	$Particles2D.position.x = outer_radius
	$Particles2D.emitting = false
	
func configure_ship(var _recipe : String, var _factory : Node2D):
	recipe = _recipe
	deposited = false
	outline_color = Global.data[recipe]["color"]
	factory = _factory.get_path()
	ship_color[0] = Global.lighten(outline_color)
	update()
	set_physics_process(true)
	visible = true
	get_parent().visible = true
	modulate = Color(1,1,1,0)
	$Tween.interpolate_property(self, "modulate", Color(1,1,1,0), Color(1,1,1,1),
		SHIP_APPEAR_TIME, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, SHIP_APPEAR_TIME, "appear_complete")
	$Tween.start()

func appear_complete():
	built = true
	something_changed_node.something_changed()

func depart():
	#print("Ship departing")
	var fac = get_node(factory) if has_node(factory) else null
	if fac != null and is_instance_valid(fac):
		fac.get_node("NewShip").start()
	$Particles2D.emitting = true
	deregister_provider(null)
	id.update_diag()
	launch = true
	rocket.play()
	# TODO improve flyaway...
	$Tween.interpolate_method(self, "set_radius_mod", 0.0, SHIP_DEPART_RADIUS + base_radius,
		SHIP_DEPART_TIME, Tween.TRANS_SINE, Tween.EASE_IN)
	$Tween.interpolate_property(self, "rotation", null, PI/4.0, SHIP_DEPART_TIME/2.0)
	$Tween.interpolate_callback(self, SHIP_DEPART_TIME, "deposit")
	$Tween.start()
	
func set_radius_mod(var r):
	radius = base_radius + r
	self.position.x = r
	
func deregister_provider(var _provider):
	if factory != "":
		var fac = get_node(factory) if has_node(factory) else null
		if fac != null and is_instance_valid(fac):
			fac.lane_cleared(self)
		factory = ""
	
func deposit():
	if deposited:
		return
	deposited = true
	rule_changer.deposit(recipe, output_storage)
	$Tween.interpolate_property(get_parent(), "modulate", Color(1,1,1,1), Color(1,1,1,0),
		SHIP_APPEAR_TIME)
	$Tween.interpolate_callback(self, SHIP_APPEAR_TIME, "remove")
	$Tween.start()
	set_physics_process(false)
	
func remove(): # Note: May remove through means other than depart()
	deregister_provider(null)
	get_parent().queue_free()
	if camera_2d.follow_target == self:
		camera_2d.stop_follow()

func try_send(var _angle : float, var _direction : int) -> bool:
	if not built or output_storage >= Global.MAX_STORAGE:
		return false
	output_storage += 1
	if output_storage == Global.MAX_STORAGE:
		depart()
	return true

func _physics_process(delta):
	var angular_velocity = Global.M_SOL/radius
	get_parent().rotation = fmod(get_parent().rotation + (delta * angular_velocity), TWOPI)
