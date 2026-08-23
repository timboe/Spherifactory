extends Node

onready var centre_node : Node2D = get_tree().get_root().find_node("CentreNode", true, false) 
onready var rs : Node2D = get_tree().get_root().find_node("RingSystem", true, false)
onready var button_group : ButtonGroup = get_tree().get_root().find_node("BuildMode", true, false).group
onready var id = get_tree().get_root().find_node("InfoDialog", true, false) 
onready var spacefield = get_tree().get_root().find_node("spacefield", true, false) 
onready var pause : Button = get_tree().get_root().find_node("Pause", true, false) 
onready var cam : Camera2D = get_tree().get_root().find_node("Camera2D", true, false) 
onready var outlines : Button = get_tree().get_root().find_node("Outlines", true, false) 

var prev_ring : Node2D = null
var ring : Node2D = null
var cursor : Vector2
var is_pan = false

func _ready():
	set_process_unhandled_input(true)

func _process(var delta):
	var button = button_group.get_pressed_button()
	var mode_build = (button != null and button.name == "BuildMode")
	
	if not pause.pressed:
		Global.time_played += delta
	
	# Update once per frame
	if mode_build and ring != null:
		var cursor_angle = get_cursor_angle()
		ring.get_node("Rotation/FactoryTemplate").global_rotation = cursor_angle
	
func _unhandled_input(event):
	if not event is InputEventMouseMotion and not event is InputEventMouseButton:
		return

	var button = button_group.get_pressed_button()
	var mode_build = (button != null and button.name == "BuildMode")
	var mode_inject = (button != null and not mode_build)
	
	var injection = null
	if mode_inject:
		injection = button.inj_node
	
	cursor = spacefield.get_global_mouse_position()
	#$Sol_light.position = cursor
	
	var dist : float = round( abs( cursor.distance_to( centre_node.position ) ) )
	var ring_index : int = int(dist / rs.RING_RADIUS) - 1 
	if dist < rs.RING_RADIUS:
		ring = rs.get_child(0)
	elif int(dist) % int(rs.RING_RADIUS) > rs.RING_WIDTH or ring_index >= Global.rings:
		ring = null
	else:
		ring = rs.get_child(ring_index)
	
	if event is InputEventMouseMotion:
		# Update once per moving in/out of highlight
		if prev_ring != ring:
			if prev_ring != null and prev_ring.ring_number != 0:
				prev_ring.get_node("OutlineHighlight").visible = false
				if (mode_build): 
					prev_ring.set_factory_template_visible(false)
				if mode_inject:
					injection.stop_hint_resource() 
			if ring != null and ring.ring_number != 0:
				ring.get_node("OutlineHighlight").visible = outlines.pressed
				if mode_build: 
					ring.set_factory_template_visible(true)
				if mode_inject:
					var free_lane = ring.get_free_or_existing_lane(injection.set_resource)
					injection.hint_resource(ring, free_lane)

		prev_ring = ring
		
	# Click down sensor
	if event is InputEventMouseButton and event.pressed and (event.button_index == 1 or event.button_index == 2):
		is_pan = false

	# Left click
	if event is InputEventMouseButton and ring != null and not event.pressed and event.button_index == 1 and not is_pan:
		if button == null: # Select ring (but not the Sol ring)
			if ring.ring_number == 0:
				if Global.DEBUG:
					print("Show sol diag")
				id.show_named_diag("Sol")
			else:
				if Global.DEBUG:
					print("Show ring diag ",ring)
				id.show_ring_diag(ring)
		elif mode_build and ring.ring_number != 0:
			if ring.new_factory():
				cam.add_trauma(0.2)
				if Global.DEBUG:
					print("New factory")
		elif mode_inject and ring.ring_number != 0:
			injection.setup_resource_at_hint()
			if Global.DEBUG:
				print("Set injection")
			
	# Right click
	if event is InputEventMouseButton and not event.pressed and event.button_index == 2 and not is_pan:
		if mode_build or mode_inject:
			button.pressed = false
			Global.last_pressed = null

func get_cursor_angle():
	var cursor_angle : float = atan2(centre_node.position.y - cursor.y, centre_node.position.x - cursor.x) - PI
	if cursor_angle < 0:
		cursor_angle += 2*PI
	return cursor_angle

