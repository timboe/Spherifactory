extends Node2D

#export(String) var inject = ""

onready var highlight : bool = "Highlight" in name
#onready var injector : bool = "Inejector" in name
onready var ring = find_parent("Ring*")


func serialise() -> Dictionary:
	var d = {}
#	d["inject"] = inject
	d["visible"] = visible
	return d
	
func deserialise(var d : Dictionary):
#	inject = d["inject"]
	visible = d["visible"] 
	#update()

func _ready():
	update()

#func change_langes():
#	update()


func _draw():
	var p : Node2D = get_parent()
	var ring_n = int(p.name)
	var to_draw : int = 0 if ring_n == 0 else Global.lanes 
	var _inner : float = p.radius_array[ 0 ] - p.LANE_OFFSET/2.0
	var outer : float = p.radius_array[ to_draw-1] + p.LANE_OFFSET/2.0
#	var width = (outer - inner) / 2.0
	var c = Color(0.36, 0.6, 0.6)
	if highlight:
		c = Color(0.48, 0.8, 0.8)

	
	if ring_n % 2 == 1:
		c = Color(0.6, 0.36, 0.6)
		if highlight:
			c = Color(0.8, 0.48, 0.8)
	
#	if not injector:
	for i in range(to_draw):
		var r : float = p.radius_array[i] - p.LANE_OFFSET/2.0
		draw_arc(Vector2(0,0), r, 0, 2*PI, 256, c, 1, true)
	draw_arc(Vector2(0,0), outer, 0, 2*PI, 256, c, 1, true)
	
#	if injector:
#		if inject != "" and get_parent().get_free_or_existing_lane(inject) != -1:
#			var mid = inner + width
#			draw_arc(Vector2(0, -mid), width, 0, 2*PI, 128, c2, 1, true)
#			draw_arc(Vector2(0, -mid), width + p.LANE_OFFSET, 0, 2*PI, 128, c1, 1, true)
	
	draw_line(Vector2(0,0), Vector2(0,0), Color(1,1,1)) # Reset palette (bug)
