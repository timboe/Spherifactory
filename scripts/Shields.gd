extends Control

var keys = []
var count = 0

onready var rendered_node = get_tree().get_root().find_node("Render", true, false)
onready var shield_scene = load("res://scenes/Shield.tscn")

func _ready():
	Global.populate_data()
	for n in get_children():
		n.queue_free()
	for n in rendered_node.get_children():
		n.queue_free()
	keys = Global.data.keys()

func set_data():
	for key in Global.data:
		Global.data[key]["texture"] = rendered_node.get_node(key).texture
	Global.goto_scene("res://Game.tscn")
	
func _process(var _delta):
	var key = keys[count]
	var value = Global.data[key]
	var shield = shield_scene.instance()
	shield.name = key
	add_child(shield, true)
	#shield.set_owner(get_tree().get_edited_scene_root())
	var back : StyleBoxFlat = shield.get_node("Back").get_stylebox("panel")
	back.bg_color = value["color"]
	back.shadow_color = value["color"].darkened(0.2)
	var label : Label = shield.get_node("Label")
	label.set("custom_colors/font_color", value["color"].contrasted())
	label.text = key
	var _sign : Label = shield.get_node("Sign")
	_sign.set("custom_colors/font_color", value["color"].contrasted())
	_sign.text = value["mode"]
	var shape : TextureRect = shield.get_node("Shape")
	var shape_outline : TextureRect = shield.get_node("ShapeOutline")
	shape.modulate = value["color"].contrasted()
	shape.texture = load("res://images/gems/gem_"+String(value["shape"])+".png")
	shape_outline.texture =  load("res://images/gems/gem_"+String(value["shape"])+".png")
	shape.visible = true
	shape_outline.visible = true
	shield.get_node("Sol").visible = false
	# Specials
	if value["special"]:
		label.text = ""
		_sign.text = ""
		shape.visible = false
		shape_outline.visible = false
	if key == "Sol":
		shield.get_node("Sol").visible = true
	# Render
	# Wait until the frame has finished before getting the texture.
	get_parent().set_update_mode(Viewport.UPDATE_ONCE)
	yield(VisualServer, "frame_post_draw")
	var img = get_parent().get_texture().get_data()
	img.lock()
	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			if img.get_pixel(x,y) == Color(0, 0, 0, 1):
				img.set_pixel(x,y, Color(0, 0, 0, 0))
	img.unlock()
	var err = img.generate_mipmaps()
	if err != OK:
		print("Failure! ", err)
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	var tr := TextureRect.new()
	rendered_node.add_child(tr)
	#tr.set_owner(get_tree().get_edited_scene_root())
	tr.texture = tex
	tr.name = key
	tr.margin_left = 256 * (count % 4)
	tr.margin_top = 256 * floor(count / 4)
	count += 1
	if count == keys.size():
		set_process(false)
		set_data()
