extends Node

# Controller for recording promotional stylized gameplay videos.
# Drives the Camera2D follow machinery (advanced_follow + follow_to_lane)
# through: injector -> ring lane -> factory -> lane -> ... -> ship launch,
# then finishes with a slow zoom-out to reveal the whole spheri-factory.

##############
# Parameters

export(int) var start_injector := 0          # Input lane (Injector0..5) the sequence starts on
export(float) var inj_start_x := -1.0        # Follow start pos along the lane (-1 = inception, far end of the input line)
export(float) var follow_zoom := 1.0/6.0     # Tight follow framing (apparent ~6x: one ring + bits of the rings either side; this build renders zoom inverted)
export(float) var zoom_variation := 0.15     # Amplitude of the zoom oscillation
export(float) var zoom_variation_period := 10.0 # Seconds per full zoom oscillation cycle
export(float) var finale_delay := 1.5        # Hold on the launching factory before the reveal
export(float) var finale_zoom := 1.6667       # Final reveal (apparent ~0.6x: whole spheri-factory in frame; build renders zoom inverted)
export(float) var finale_duration := 8.0     # Seconds for the zoom-out / centre on the sun
export(float) var max_duration := 0.0        # Optional safety timeout (0 = unlimited)
export(bool) var show_debug := true          # Show the on-screen status readout (F10 toggles)

##############
# State

enum {IDLE, FOLLOWING, FINALE_HOLD, FINALE}

var camera : Camera2D = null
var ui : Control = null
var injection : Node2D = null

var state := IDLE
var time := 0.0

var finale_t := 0.0
var finale_start_pos : Vector2
var finale_start_rot := 0.0
var finale_start_zoom := 1.0
var finale_target_pos : Vector2

var ui_was_visible := true

var debug_label : Label = null
var last_follow_name := ""
var last_status_time := 0.0

func _ready():
	camera = get_tree().get_root().find_node("Camera2D", true, false) as Camera2D
	ui = get_tree().get_root().find_node("UI", true, false) as Control
	injection = get_tree().get_root().find_node("InjectionSystem", true, false) as Node2D
	var layer := CanvasLayer.new()
	layer.name = "TrailerDebugLayer"
	debug_label = Label.new()
	debug_label.rect_position = Vector2(8, 8)
	debug_label.add_color_override("font_color", Color(1, 1, 0, 1))
	debug_label.visible = show_debug
	layer.add_child(debug_label)
	add_child(layer)
	set_process_input(true)
	set_process(true)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_F10:
		debug_label.visible = not debug_label.visible

func _process(delta):
	update_debug()
	if Input.is_action_just_pressed("trail_start"):
		toggle()
		return
	time += delta
	match state:
		IDLE:
			pass
		FOLLOWING:
			update_follow_zoom()
			if timed_out() or camera.follow_target == null or not is_instance_valid(camera.follow_target):
				stop()
				return
			if ship_launched():
				state = FINALE_HOLD
				finale_t = 0.0
		FINALE_HOLD:
			update_follow_zoom()
			if timed_out():
				stop()
				return
			finale_t += delta
			if finale_t >= finale_delay:
				start_finale()
		FINALE:
			update_finale(delta)

func update_debug():
	var follow_name : String = "none"
	var z : float = 0.0
	var zt : float = 0.0
	var px : float = 0.0
	var py : float = 0.0
	var rot : float = 0.0
	if camera != null:
		if camera.follow_target != null and is_instance_valid(camera.follow_target):
			follow_name = str(camera.follow_target.name)
		z = camera.zoom.x
		zt = camera.zoom_target.x
		px = camera.global_position.x
		py = camera.global_position.y
		rot = rad2deg(camera.rotation)
	if follow_name != last_follow_name:
		last_follow_name = follow_name
		print("Trailer follow -> ", follow_name)
	if debug_label.visible:
		debug_label.text = "Trailer state: %d\nfollow: %s\nzoom: %.2f  target: %.2f\npos: (%.0f, %.0f)  rot: %.1f" % [state, follow_name, z, zt, px, py, rot]
	if time - last_status_time > 2.0:
		last_status_time = time
		print("Trailer [state ", state, "] zoom=", z, " target=", zt, " pos=(", px, ", ", py, ") follow=", follow_name)

func toggle():
	if state == IDLE:
		start()
	else:
		stop()

func start():
	if camera == null:
		return
	var mm = find_start_injector()
	if mm == null:
		print("TrailerController: no placed injector to follow")
		return
	camera.follow_dict.clear()
	# Start at the far end of the line (inception) so the unit is traced to the ring
	var line_length : float = mm.n * mm.linear_velocity * mm.set_period
	camera.follow_dict["inj_x"] = (mm.transform.origin.x - line_length) if inj_start_x < 0.0 else inj_start_x
	camera.follow_target = mm
	camera.ADVANCED_FOLLOW = true
	camera.set_physics_process(true)
	state = FOLLOWING
	time = 0.0
	hide_ui(true)
	print("Trailer sequence started on ", mm.name, " inj_x=", camera.follow_dict["inj_x"], " follow_zoom=", follow_zoom)

func stop():
	if camera != null:
		camera.stop_follow()
	state = IDLE
	time = 0.0
	hide_ui(false)
	print("Trailer sequence stopped")

func find_start_injector():
	if injection == null:
		return null
	var mm = get_injector_mm(start_injector)
	if mm != null and mm.placed:
		return mm
	for i in range(Global.MAX_INPUT_LANES):
		mm = get_injector_mm(i)
		if mm != null and mm.placed:
			return mm
	return null

func get_injector_mm(var i : int):
	var inj = injection.get_node_or_null("Injector" + String(i))
	if inj == null:
		return null
	return inj.get_node_or_null("InjectorMm")

func update_follow_zoom():
	var z : float = follow_zoom
	if zoom_variation > 0.0 and zoom_variation_period > 0.0:
		z *= 1.0 + zoom_variation * sin(time * TAU / zoom_variation_period)
	camera.zoom_target = Vector2.ONE * clamp(z, camera.min_zoom, camera.max_zoom)

func timed_out() -> bool:
	return max_duration > 0.0 and time > max_duration

# The sequence ends when the factory we are viewing launches its ship
func ship_launched() -> bool:
	var trg = camera.follow_target
	if trg == null or not is_instance_valid(trg):
		return false
	if "Ship" in trg.name:
		return trg.launch == true
	if "Factory" in trg.name:
		var proc = trg.get_node_or_null("FactoryProcess")
		if proc != null and proc.ship != null and is_instance_valid(proc.ship):
			return proc.ship.launch == true
	return false

func start_finale():
	state = FINALE
	finale_t = 0.0
	finale_start_pos = camera.global_position
	finale_start_rot = camera.rotation
	finale_start_zoom = camera.zoom.x
	finale_target_pos = -camera.offset
	# Decouple from the factory - the controller now owns the camera motion
	camera.follow_target = null
	camera.rotating = false
	print("Trailer finale: zoom ", finale_start_zoom, " -> ", finale_zoom, " over ", finale_duration, "s")

func update_finale(delta):
	finale_t += delta
	var p : float = clamp(finale_t / finale_duration, 0.0, 1.0)
	p = p * p * (3.0 - 2.0 * p) # Smoothstep
	camera.rotation = lerp(finale_start_rot, 0.0, p)
	camera.global_position = finale_start_pos.linear_interpolate(finale_target_pos, p)
	camera.zoom_target = Vector2.ONE * lerp(finale_start_zoom, finale_zoom, p)
	if finale_t >= finale_duration:
		camera.stop_follow()
		state = IDLE
		time = 0.0
		hide_ui(false)
		print("Trailer sequence finished")

func hide_ui(var hide : bool):
	if ui == null:
		return
	if hide:
		ui_was_visible = ui.visible
		ui.visible = false
	else:
		ui.visible = ui_was_visible
