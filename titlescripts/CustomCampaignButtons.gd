extends Button

onready var tab_container : TabContainer = find_parent("CampaignEditor").find_node("TabContainer", true, false)
onready var warn_diag : AcceptDialog = find_parent("CampaignEditor").find_node("WarningDialog", true, false)
onready var discard_conf_diag : ConfirmationDialog = find_parent("CampaignEditor").find_node("DiscardConfirmationDialog", true, false)
onready var overwrite_conf_diag : ConfirmationDialog = find_parent("CampaignEditor").find_node("OverwriteConfirmationDialog", true, false)
onready var campaign_name : LineEdit = find_parent("CampaignEditor").find_node("CampaignName", true, false)
onready var campaign : CenterContainer = find_parent("CampaignEditor")
onready var main_menu : CenterContainer = get_tree().get_root().find_node("MainMenu",true,false)

var the_campaign : Dictionary

func _on_Save_pressed():
	var bad_missions : String = ""
	var first = true
	for c in tab_container.get_children():
		var warn = c.find_node("WarningButton", true, false)
		if warn.visible:
			if first:
				first = false
			else:
				bad_missions += ", "
			bad_missions += c.name
	if bad_missions != "":
		warn_diag.dialog_text = tr("ui_config_issue_1")+"\n\n"
		warn_diag.dialog_text += tr("ui_config_issue_2")+"\n\n"
		warn_diag.dialog_text += bad_missions
		warn_diag.popup_centered()
		return
		
	if campaign_name.text == "ui_main_campaign" or campaign_name.text == "Main Campaign": 
		pass
		#warn_diag.dialog_text = tr("ui_overwrite_main_1") + "\n\n"
		#warn_diag.dialog_text += tr("ui_overwrite_main_2")
		#warn_diag.popup_centered()
		#return
		
	if campaign_name.text == "":
		warn_diag.dialog_text = tr("ui_no_campaign_name")
		warn_diag.popup_centered()
		return
		
	the_campaign = campaign.dictionise()
	if the_campaign["name"] in Global.campaigns:
		overwrite_conf_diag.popup_centered()
	else:
		_on_OverwriteConfirmationDialog_confirmed()

	
func _on_Discard_pressed():
	discard_conf_diag.popup_centered()

func _on_DiscardConfirmationDialog_confirmed():
	print("Discard")
	main_menu.show_menu("CampaignManager")

func _on_OverwriteConfirmationDialog_confirmed():
	Global.campaigns[ the_campaign["name"] ] = the_campaign
	campaign.flush_campaign_to_disk()
	main_menu.show_menu("CampaignManager")
