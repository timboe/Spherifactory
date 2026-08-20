extends HBoxContainer

var lanes = []
onready var ring = find_parent("Ring*")

func _ready():
	for l in ring.find_node("Lanes", true, false).get_children():
		lanes.append(l)

func update_content():
	var p : Node2D = get_parent()
	var to_draw : int =  Global.lanes 
	var inner : float = p.radius_array[ 0 ] - p.LANE_OFFSET/2.0
	var outer : float = p.radius_array[ to_draw-1] + p.LANE_OFFSET/2.0
	var width = (outer - inner) / 2.0
	
	for c in get_children():
		c.visible = false
	for i in range(to_draw):
		if i >= lanes.size():
			continue
		if lanes[i] != null and is_instance_valid(lanes[i]) and lanes[i].lane_content != null and ring.ring_number > 0:
			get_child(i).texture = Global.data[lanes[i].lane_content]["texture"]
			get_child(i).visible = true
			
	rect_position = Vector2(-outer, -(inner + width + 16))
	rect_size.x = 2*outer
