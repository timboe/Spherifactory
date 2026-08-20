extends Node2D

func _ready():
	var buttons : Array = get_tree().get_nodes_in_group("ButtonsGroup")
	for i in buttons:
		if is_instance_valid(i) and not i.is_connected("pressed", self, "on_button_pressed"):
			i.connect("pressed", self, "on_button_pressed")
		
func refresh():
	_ready()

func on_button_pressed():
	$"/root/Sfx/Click".play()
