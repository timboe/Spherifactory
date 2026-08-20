extends WindowDialog

onready var tab_container : TabContainer = get_tree().get_root().find_node("TabContainer", true, false)

var hints_array : Array

func _ready():
	for _i in range(20):
		hints_array.append([])
		hints_array.back().append("Hint #1")
		hints_array.back().append("Hint #2")
		hints_array.back().append("Hint #3")

func _on_Hints_about_to_show():
	var level : int = tab_container.get_current_tab()
	$MarginContainer/VBoxContainer/HintEdit1.text = hints_array[level][0]
	$MarginContainer/VBoxContainer/HintEdit2.text = hints_array[level][1]
	$MarginContainer/VBoxContainer/HintEdit3.text = hints_array[level][2]
	print("Show for tab ",level)


func _on_Hints_popup_hide():
	var level : int = tab_container.get_current_tab()
	hints_array[level][0] = $MarginContainer/VBoxContainer/HintEdit1.text
	hints_array[level][1] = $MarginContainer/VBoxContainer/HintEdit2.text 
	hints_array[level][2] = $MarginContainer/VBoxContainer/HintEdit3.text 
	hide()
	print("Hide for tab ",level)
