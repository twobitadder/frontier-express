extends ColorRect


func _on_start_pressed() -> void:
	SceneHandler.change_scene("Game")


func _on_credits_pressed() -> void:
	SceneHandler.change_scene("Credits")


func _on_quit_pressed() -> void:
	get_tree().quit()
