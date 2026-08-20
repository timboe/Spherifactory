extends Camera2D

const MOVE_SPEED = 300


##############################
# Shake parameters

export var shake_speed := 0.8
export var shake_decay := 0.3
export var noise : OpenSimplexNoise

onready var info_dialog : WindowDialog = get_tree().get_root().find_node("InfoDialog",true,false)
onready var input_capture : Node2D = get_tree().get_root().find_node("InputCapture",true,false)
onready var ui : Control = get_tree().get_root().find_node("UI",true,false)

const RUMBLE_OFFSET : float = 0.75

var slow_mo_count : int = 0

var trauma := 0.0
var time := 0.0

var down_point : Vector2

var events = {}
var last_drag_distance = 0
var pan_zoom_sensitivity = 10
var zoom_speed = 0.05
var min_zoom := 0.05 # 0.5
var max_zoom := 20.0 # 2
var zoom_target : Vector2 = zoom



### Section for advanced follow, for trailer
var ADVANCED_FOLLOW = true
var follow_target = null
var follow_dict = {}
var global_position_target : Vector2
var ignore : bool = false
###

func _ready():
	set_process_unhandled_input(true)
	set_physics_process(false)

func _unhandled_input(event):
	var change = false

	# Zoom mouse
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP and zoom_target.x > min_zoom:
			zoom_target /= 1.1
			change = true
		if event.button_index == BUTTON_WHEEL_DOWN and zoom_target.x < max_zoom:
			zoom_target *= 1.1
			change = true
		down_point = event.position
	# Pan mouse
	if event is InputEventMouseMotion and Input.is_action_pressed("ui_mouse_pan"):
		global_position -= event.relative.rotated(rotation) * zoom.x
		change = true
		if down_point.distance_to(event.position) > pan_zoom_sensitivity:
			input_capture.is_pan = true
	# Android touch
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
			down_point = event.position
		else:
			events.erase(event.index)
	if event is InputEventScreenDrag:
		events[event.index] = event
		# Pan android
		if events.size() == 1:
			global_position -= event.relative.rotated(rotation) * zoom.x
			change = true
			if down_point.distance_to(event.position) > pan_zoom_sensitivity:
				input_capture.is_pan = true
		# Zoom android
		elif events.size() == 2:
			var drag_distance = events[0].position.distance_to(events[1].position)
			if abs(drag_distance - last_drag_distance) > pan_zoom_sensitivity:
				var new_zoom = (1 + zoom_speed) if drag_distance < last_drag_distance else (1 - zoom_speed)
				new_zoom = clamp(zoom_target.x * new_zoom, min_zoom, max_zoom)
				zoom_target = Vector2.ONE * new_zoom
				last_drag_distance = drag_distance
				input_capture.is_pan = true
				change = true
	## Update
	if change:
		var zoom_mod = clamp(zoom_target.x, 1.0, 2.0) / 1.5
		var w : float = ProjectSettings.get_setting("display/window/size/width") * zoom_mod
		var h : float = ProjectSettings.get_setting("display/window/size/height") * 1.3 * zoom_mod
		global_position.x = clamp(global_position.x, -w, w)
		global_position.y = clamp(global_position.y, -h, h)

func _process(delta):
	apply_shake(delta)
	decay_trauma(delta)
	
	zoom = zoom + (zoom_target - zoom) * delta * 5.0
	
	if Input.is_action_pressed("ui_left"):
		global_position += Vector2.LEFT * delta * MOVE_SPEED * zoom.x
	elif Input.is_action_pressed("ui_right"):
		global_position += Vector2.RIGHT * delta * MOVE_SPEED * zoom.x
	if Input.is_action_pressed("ui_up"):
		global_position += Vector2.UP * delta * MOVE_SPEED * zoom.x
	elif Input.is_action_pressed("ui_down"):
		global_position += Vector2.DOWN * delta * MOVE_SPEED * zoom.x
		
	if Input.is_action_just_pressed("toggle_ui"):
		ui.visible = !ui.visible
				
	if Input.is_action_just_pressed("trail_start"):
		if follow_target:
			return stop_follow()
		follow_dict.clear()
		var inj0 = get_tree().get_root().find_node("Injector0",true,false)
		if inj0 == null or inj0.get_node("InjectorMm") == null:
			return
		follow_target = inj0.get_node("InjectorMm")
		follow_dict["inj_x"] = -770
		ADVANCED_FOLLOW = true
		set_physics_process(true)
		#
		#follow_target = get_tree().get_root().find_node("Ring11",true,false).get_node("Rotation/Lanes/Lane0")
		print("Follow is ",follow_target," ", follow_target.name)

### Follow cam

func _physics_process(delta):
	if follow_target == null or not is_instance_valid(follow_target):
		stop_follow()
		return
	if ADVANCED_FOLLOW:
		advanced_follow(delta)
	else:
		follow()
	global_position = global_position + (global_position_target - global_position) * delta * 5.0

func follow():
	var trg = follow_target
	if trg == null or not is_instance_valid(trg):
		stop_follow()
		return
	rotation = trg.get_global_transform().get_rotation() + PI/2.0
	var the_ring : Node2D = trg.get_ring() if trg.has_method("get_ring") else trg.ring
	if the_ring == null or not (the_ring is Node2D) or not is_instance_valid(the_ring):
		return
	global_position_target = trg.global_position - Vector2(640,360) - Vector2(0, the_ring.radius_array[0] ).rotated(rotation)
	rotating = true
	
func stop_follow():
	rotating = false
	rotation = 0
	follow_target = null
	set_physics_process(false)

func advanced_follow(var delta):
	#
	#global_position = follow_target.global_position - Vector2(640,360) - Vector2(0, follow_target.ring.radius_array[0] ).rotated(rotation)
	#rotating = true
	if "Injector" in follow_target.name:
		rotating = false
		follow_dict["inj_x"] += follow_target.linear_velocity * delta
		global_position_target = Vector2(follow_dict["inj_x"], -follow_target.radius)
		if follow_dict["inj_x"] > 0:
			# Goto LANE
			follow_dict.clear()
			var ring = get_node(follow_target.ring)
			if ring == null or not is_instance_valid(ring):
				stop_follow()
				return
			# Get the angle at the "top" where we want to add an item
			var angle_mod = (1.5 * PI) - ring.get_node("Rotation").rotation
			var lane = ring.get_lane(follow_target.lane)
			var slot = lane.get_slot(angle_mod)
			# Correct the angle mod w.r.t current rotation
			angle_mod += ring.get_node("Rotation").rotation + (0.5 * PI)
			follow_dict["slot"] = slot
			follow_dict["ring"] = ring
			follow_dict["offset"] = angle_mod
			follow_dict["mid_flight"] = false
			follow_target = lane
			lane.highlight(slot)
			print("Move to lane ", lane, " with slot ", slot," at angle ",rad2deg(angle_mod))
	elif "Lane" in follow_target.name:
		if get_tree().paused == false:
			follow_dict["offset"] = fmod(follow_dict["offset"] + (delta * follow_dict["ring"].angular_velocity), PI*2)
		rotation = follow_dict["offset"]
		# TODO add offset for lane_slot
		rotating = true
		#check if in flight
		var radius_mod = follow_target.radius
		var in_flight_now = false
		for in_flight in follow_target.in_flight:
			if in_flight["i"] == follow_dict["slot"]:
				radius_mod = in_flight["radius"]
				in_flight_now = true
				follow_dict["mid_flight"] = true
				if "call" in in_flight and not "call" in follow_dict:
					follow_dict["call"] = in_flight["call"]
				break
		var r = follow_target.radius + (follow_target.radius - radius_mod)
		global_position_target = follow_target.global_position - Vector2(640,360) - Vector2(0,  + radius_mod).rotated(rotation)
		if in_flight_now == false and follow_dict["mid_flight"] == true:
			if "call" in follow_dict:
				# Reached end of OUTGOING fligt, goto FACTORY
				follow_target = follow_dict["call"]
				follow_dict.clear()
				print("Move to factory ",follow_target)
			else:
				# Reached ring
				follow_dict["mid_flight"] = false
				# Is there a laneswap?
				if follow_target.laneswap_target[0] != null:
					follow_target = follow_target.laneswap_target[0] 
				
	elif "Factory" in follow_target.name or "Ship" in follow_target.name:
		rotation = follow_target.get_global_transform().get_rotation() + PI/2.0
		global_position_target = follow_target.global_position - Vector2(640,360) - Vector2(0, follow_target.ring.radius_array[2] ).rotated(rotation)
		rotating = true
	

func follow_to_lane(var output_lane, var glob_angle):
	if output_lane == null or not is_instance_valid(output_lane):
		return
	if "Ship" in output_lane.name:
		follow_target = output_lane
		follow_target.depart()
		print("Moving to ship ", output_lane)
		return
	var slot = output_lane.get_slot_from_global_angle(glob_angle)
	var ring = output_lane.get_ring()
	# Correct the angle mod w.r.t current rotation
	var angle_mod = output_lane.get_angle(slot) + ring.get_node("Rotation").rotation + (0.5 * PI)
	follow_dict.clear()
	follow_dict["slot"] = slot
	follow_dict["ring"] = ring
	follow_dict["offset"] = angle_mod
	follow_dict["mid_flight"] = false # Technically true
	follow_target = output_lane
	print("Moving to lane ", output_lane)
	#output_lane.highlight(slot)

	
###

func add_trauma(var amount):
	if Global.settings["shake"] == false:
		return
	trauma = min(trauma + amount, amount * 2)
 
func decay_trauma(var delta: float):
	var change := shake_decay * delta
	trauma = max(trauma - change, 0.0)
 
# apply shake to starting camera position
func apply_shake(var delta : float):
	# using a magic number here to get a pleasing effect at speed 1.0
	time += delta * shake_speed * 5000.0
	if trauma == 0:
		return
	var shake := trauma * trauma
	var offset_x := RUMBLE_OFFSET * shake * noise.get_noise_2d(0, time)
	var offset_y := RUMBLE_OFFSET * shake * noise.get_noise_2d(time, 0)
	offset_h = offset_x
	offset_v = offset_y


func _on_Rotate_toggled(button_pressed):
	if ignore:
		return
	if button_pressed:
		follow_target = info_dialog.current_building
		set_physics_process(true)
		ADVANCED_FOLLOW = false
	else:
		stop_follow()
