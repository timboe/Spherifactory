extends Control

onready var sol = get_tree().get_root().find_node("Sol",true,false)
onready var id = get_tree().get_root().find_node("InfoDialog", true, false) 

const OFF_MAX := 100.0
var offset : float = 0
var show : bool = false

func _on_Pause_toggled(button_pressed):
	if Global.DEBUG:
		print("Pause ", button_pressed)
	get_tree().paused = button_pressed
	if sol != null and is_instance_valid(sol):
		sol.get_material().set_shader_param("paused", button_pressed)

func _on_FF_toggled(button_pressed):
	Engine.time_scale = 2.0 if button_pressed else 1.0
	if Global.DEBUG:
		print("Game speed ", Engine.time_scale)

func _on_Outlines_toggled(button_pressed):
	for o in get_tree().get_nodes_in_group("RingOutlineGroup"):
		o.visible = button_pressed
	for c in get_tree().get_nodes_in_group("RingContentGroup"):
		c.visible = button_pressed
	for o in get_tree().get_nodes_in_group("RingOutlineHLGroup"):
		o.visible = false
	for i in get_tree().get_nodes_in_group("InjectorLinesGroup"):
		if button_pressed:
			i.visible = i.mm.visible
		else: 
			i.visible = false
			
func _on_Menu_pressed():
	id.toggle_menu_diag()

func _process(delta):
	if Global.settings["hide"] == false:
		$MarginContainerSide.rect_position.x = 0
		$MarginContainerTop.rect_position.y = 0
		set_process(false)
		return
	if show:
		offset = max(0, offset - delta * 500.0)
	else:
		offset = min(OFF_MAX, offset + delta * 500.0)
	$MarginContainerSide.rect_position.x = -offset
	$MarginContainerTop.rect_position.y = -offset/2.0


func _on_mouse_entered():
	show = true

func _on_mouse_exited():
	show = false

