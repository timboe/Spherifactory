extends AudioStreamPlayer


var tracks = []
var current : int
var R = RandomNumberGenerator.new()
var started = false

func start_music():
	if started:
		return
	started = true
	R.randomize()
	current = 0
	tracks.append(load("res://resources/ader-da-silva-rareness-of-existence-4314.ogg"))
	tracks.append(load("res://resources/ader-da-silva-phyllodia-1451.ogg"))
	tracks.append(load("res://resources/ader-da-silva-naval-proeminence-1450.ogg"))
	for t in tracks:
		if t == null:
			continue
		t.loop = false
	stream = tracks[0]
	play()

func _on_Music_finished():
	if tracks.size() == 0:
		return
	var next = current
	while next == current and tracks.size() > 1:
		next = R.randi() % tracks.size()
	stream = tracks[next]
	current = next
	if Global.DEBUG:
		print("play ",current)
	play()
