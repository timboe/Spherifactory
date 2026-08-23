extends WindowDialog

onready var tab_container : TabContainer = get_tree().get_root().find_node("TabContainer", true, false)

var hints_array : Array

func _ready():
	for _i in range(20):
		hints_array.append([])
		hints_array.back().append("Hint #1")
		hints_array.back().append("Hint #2")
		hints_array.back().append("Hint #3")

func set_hints(level : int, mission_hints : Array):
	var new_hints := []
	for i in range(3):
		if i < mission_hints.size():
			new_hints.append(mission_hints[i])
		else:
			new_hints.append("Hint #" + String(i + 1))
	hints_array[level] = new_hints

func _on_Hints_about_to_show():
	var level : int = tab_container.get_current_tab()
	set_hints(level, hints_array[level])
	$MarginContainer/VBoxContainer/HintEdit1.text = hints_array[level][0]
	$MarginContainer/VBoxContainer/HintEdit2.text = hints_array[level][1]
	$MarginContainer/VBoxContainer/HintEdit3.text = hints_array[level][2]
	if Global.DEBUG:
		print("Show for tab ",level)


func _on_Hints_popup_hide():
	var level : int = tab_container.get_current_tab()
	set_hints(level, hints_array[level])
	hints_array[level][0] = $MarginContainer/VBoxContainer/HintEdit1.text
	hints_array[level][1] = $MarginContainer/VBoxContainer/HintEdit2.text 
	hints_array[level][2] = $MarginContainer/VBoxContainer/HintEdit3.text 
	hide()
	if Global.DEBUG:
		print("Hide for tab ",level)
