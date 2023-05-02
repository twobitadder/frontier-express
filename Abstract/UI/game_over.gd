extends MarginContainer


func _ready() -> void:
	var text = "Bad luck! "
	if GameState.strikes <= 0:
		text += "You failed one too many deliveries and were driven out of the system by angry residents."
	else:
		text += "Your poor ship could not withstand the stresses of frontier delivery."
	
	text +="
	Final Revenue: $%s" % str(GameState.money)
	
	$VBoxContainer/EndingSummary.text = text

func _on_retry_pressed() -> void:
	GameState.reset()
	SceneHandler.change_scene("Game")


func _on_main_menu_pressed() -> void:
	SceneHandler.change_scene("Main Menu")


func _on_quit_pressed() -> void:
	get_tree().quit()
