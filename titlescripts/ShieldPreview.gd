extends TextureRect

onready var shield = get_tree().get_root().find_node("Shield", true, false)
onready var col : ColorPicker = find_parent("CustomResourceDialog").find_node("ColorPicker")
onready var nme : LineEdit = find_parent("CustomResourceDialog").find_node("LineEdit")
onready var symb : OptionButton = find_parent("CustomResourceDialog").find_node("SymbolButton")
onready var mode : OptionButton = find_parent("CustomResourceDialog").find_node("ModeButton")

onready var shape : TextureRect = shield.get_node("Shape")
onready var shape_outline : TextureRect = shield.get_node("ShapeOutline")
onready var back : StyleBoxFlat = shield.get_node("Back").get_stylebox("panel")
onready var label : Label = shield.get_node("Label")
onready var _sign : Label = shield.get_node("Sign")

# Called when the node enters the scene tree for the first time.
func _ready():
	shield.get_node("Back2").get_stylebox("panel").bg_color = Color(0.22,0.21,0.25)
	update_prieview()
	
func update_prieview():
	var gem_id = symb.get_selected_metadata()
	
	back.bg_color = col.color
	back.shadow_color = col.color.darkened(0.2)

	label.set("custom_colors/font_color", col.color.contrasted())
	label.text = nme.text
	
	_sign.set("custom_colors/font_color", col.color.contrasted())
	_sign.text = mode.get_selected_metadata()

	shape.modulate = col.color.contrasted()
	shape.texture =         load("res://images/gems/gem_"+String(gem_id)+".png")
	shape_outline.texture = load("res://images/gems/gem_"+String(gem_id)+".png")

func _on_ColorPicker_color_changed(_color):
	 update_prieview()

func _on_LineEdit_text_changed(_new_text):
	 update_prieview()

func _on_SymbolButton_item_selected(_index):
	 update_prieview()

func _on_ModeButton_item_selected(_index):
	 update_prieview()

func _on_CustomResourceDialog_about_to_show():
	 update_prieview()
