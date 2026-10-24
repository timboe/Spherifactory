extends MenuButton

onready var pop : PopupMenu = get_popup() 
onready var settings : CenterContainer = get_tree().get_root().find_node("Settings", true, false)
var lang : String

func _ready():
	pop.add_item("Deutsch", 0)
	pop.add_item("English", 1)
	pop.add_item("Español", 2)
	pop.add_item("Français", 3)
	pop.add_item("Bahasa Indonesia", 4)
	pop.add_item("Italiano", 5)
	pop.add_item("日本語", 6)
	pop.add_item("한국어", 7)
	pop.add_item("Polski", 8)
	pop.add_item("Português (Brasil)", 9)
	pop.add_item("Русский", 10)
	pop.add_item("Tiếng Việt", 11)
	pop.add_item("简体中文", 12)

	pop.set_item_metadata(0, "de")
	pop.set_item_metadata(1, "en")
	pop.set_item_metadata(2, "es")
	pop.set_item_metadata(3, "fr")
	pop.set_item_metadata(4, "id")
	pop.set_item_metadata(5, "it")
	pop.set_item_metadata(6, "ja")
	pop.set_item_metadata(7, "ko")
	pop.set_item_metadata(8, "pl")
	pop.set_item_metadata(9, "pt_BR")
	pop.set_item_metadata(10, "ru")
	pop.set_item_metadata(11, "vi")
	pop.set_item_metadata(12, "zh_Hans_CN")
	
	pop.connect("index_pressed", self, "_on_MenuButton_index_pressed")

func _on_MenuButton_index_pressed(var i):
	lang = pop.get_item_metadata(i)
	TranslationServer.set_locale(lang)
	settings._on_Back_pressed()

