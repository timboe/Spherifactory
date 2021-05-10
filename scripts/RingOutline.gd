extends Node2D

export(bool) var highlight setget set_highlight
export(String) var inject = ""
export(bool) var show setget set_show

onready var ring = find_parent("Ring*")
var lanes = []

func serialise() -> Dictionary:
	var d = {}
	d["highlight"] = highlight
	d["inject"] = inject
	d["show"] = show
	return d
	
func deserialise(var d : Dictionary):
	highlight = d["highlight"]
	inject = d["inject"]
	show = d["show"] 
	#update()

func _ready():
	for l in ring.find_node("Lanes", true, false).get_children():
		lanes.append(l)

func set_highlight(var i : bool):
	highlight = i
	update()
	
func set_inject(var i:  bool, var resource : String):
	inject = resource if i else ""
	update()

func set_show(var i : bool):
	show = i
	update()

func _draw():
	var p : Node2D = get_parent()
	var to_draw : int = 0 if p.name == "Ring0" else Global.lanes 
	var inner : float = p.radius_array[ 0 ] - p.LANE_OFFSET/2.0
	var outer : float = p.radius_array[ to_draw-1] + p.LANE_OFFSET/2.0
	var width = (outer - inner) / 2.0
	var hl : float = 0.2 if highlight else 0.0
	var c1 = Color(0.8 + hl, 0.8 + hl, 0.8 + hl)
	var c2 = Color(0.6 + hl, 0.6 + hl, 0.6 + hl)
	
	var hb = $"../HBoxContainer"
	if show:
		for c in hb.get_children():
			c.visible = false
		for i in range(to_draw):
			var r : float = p.radius_array[i] - p.LANE_OFFSET/2.0
			var c = c1 if i == 0 else c2
			draw_arc(Vector2(0,0), r, 0, 2*PI, 256, c, 1, true)
			if lanes[i].lane_content != null and ring.ring_number > 0:
				hb.get_child(i).texture = Global.data[lanes[i].lane_content]["texture"]
				hb.get_child(i).visible = true
		hb.visible = true
		hb.rect_position = Vector2(-outer, -(inner + width + 16))
		hb.rect_size.x = 2*outer
		
		draw_arc(Vector2(0,0), outer, 0, 2*PI, 256, c1, 1, true)
	else:
		hb.visible = false
	
	if inject != "" and get_parent().get_free_or_existing_lane(inject) != -1:
		var mid = inner + width
		draw_arc(Vector2(0, -mid), width, 0, 2*PI, 128, c2, 1, true)
		draw_arc(Vector2(0, -mid), width + p.LANE_OFFSET, 0, 2*PI, 128, c1, 1, true)
	
	draw_line(Vector2(0,0), Vector2(0,0), Color(1,1,1)) # Reset palette (bug)
