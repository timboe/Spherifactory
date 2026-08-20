extends Sprite

var anim_time := 0.0

func _process(delta):
	if not get_tree().paused:
		anim_time += delta
	material.set_shader_param("anim_time", anim_time)
