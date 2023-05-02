extends ColorRect


func _on_start_pressed() -> void:
	SceneHandler.change_scene("Game")


func _on_credits_pressed() -> void:
	SceneHandler.change_scene("Credits")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_music_toggle_pressed() -> void:
	SceneHandler.music_enabled = !SceneHandler.music_enabled
	if SceneHandler.music_enabled:
		$MarginContainer/VBoxContainer/MusicToggle.text = "Music Enabled"
	elif !SceneHandler.music_enabled:
		$MarginContainer/VBoxContainer/MusicToggle.text = "Music Disabled"
