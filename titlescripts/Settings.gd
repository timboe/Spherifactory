extends CenterContainer

onready var lang_menu : MenuButton = get_tree().get_root().find_node("LanguageButton", true, false)

func show_settings():
	$MC/MC/VB/SC/VB2/FullscreenButton.pressed = OS.window_fullscreen
	$MC/MC/VB/SC/VB2/SunButton.pressed = Global.settings["fancy_sun"]
	$MC/MC/VB/SC/VB2/ShakeButton.pressed = Global.settings["shake"]
	$MC/MC/VB/SC/VB2/HideButton.pressed = Global.settings["hide"]
	$MC/MC/VB/SC/VB2/TutorialButton.pressed = Global.settings["tutorial"]
	$MC/MC/VB/SC/VB2/SG/MusicSlider.value = Global.settings["music"]
	$MC/MC/VB/SC/VB2/SG/SFXSlider.value = Global.settings["sfx"]
	$MC/MC/VB/SC/VB2/SG/BeepsSlider.value = Global.settings["beeps"]

func set_default():
	Global.settings["music"] = 100
	Global.settings["sfx"] = 100
	Global.settings["beeps"] = 20
	Global.settings["fancy_sun"] = true
	Global.settings["shake"] = true	
	Global.settings["hide"] = false
	Global.settings["fullscreen"] = OS.window_fullscreen
	Global.settings["tutorial"] = true
	Global.settings["lang"] = "en"
	
func _on_FullscreenButton_toggled(button_pressed):
	OS.window_fullscreen = button_pressed
	Global.settings["fullscreen"] = button_pressed

func _on_Back_pressed():
	Global.settings["music"] = $MC/MC/VB/SC/VB2/SG/MusicSlider.value
	Global.settings["sfx"] = $MC/MC/VB/SC/VB2/SG/SFXSlider.value
	Global.settings["beeps"] = $MC/MC/VB/SC/VB2/SG/BeepsSlider.value
	Global.settings["fancy_sun"] = $MC/MC/VB/SC/VB2/SunButton.pressed
	Global.settings["shake"] = $MC/MC/VB/SC/VB2/ShakeButton.pressed
	Global.settings["hide"] = $MC/MC/VB/SC/VB2/HideButton.pressed
	Global.settings["tutorial"] = $MC/MC/VB/SC/VB2/TutorialButton.pressed
	Global.settings["lang"] = lang_menu.lang
	
	var file = File.new()
	file.open(Global.SETTINGS_SAVE_FILE, File.WRITE)
	file.store_string(JSON.print(Global.settings))
	file.close()
	
	get_parent().get_node("MainMenu")._on_Back_pressed()

func _on_MusicSlider_value_changed(var value):
	Music.volume_db = linear2db(value * 0.01)
	 

func _on_SFXSlider_changed(var value):
	for c in Sfx.get_children():
		if "Blip" in c.name:
			continue
		c.volume_db = linear2db(value * 0.01)


func _on_BeepsSlider_changed(var value):
	for c in Sfx.get_children():
		if not "Blip" in c.name:
			continue
		c.volume_db = linear2db(value * 0.01)
