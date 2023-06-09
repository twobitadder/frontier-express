extends Node

var music_enabled := true:
	get:
		return music_enabled
	set(value):
		if value:
			$AudioStreamPlayer.stream = scenes["Main Menu"][1]
			$AudioStreamPlayer.play()
		elif !value:
			$AudioStreamPlayer.stop()
		music_enabled = value

var current_scene := "Main Menu"

const scenes = {
	"Main Menu" : [preload("res://Abstract/UI/MainMenu.tscn"), preload("res://Assets/Music/bgm_action_5.mp3")],
	"Credits" : [preload("res://Abstract/UI/Credits.tscn"), preload("res://Assets/Music/bgm_action_2.mp3")],
	"Game" : [preload("res://World/SolarSystem.tscn"), preload("res://Assets/Music/bgm_action_3.mp3")],
	"Game Over" : [preload("res://Abstract/UI/GameOver.tscn"), preload("res://Assets/Music/bgm_action_4.mp3")]
}

func change_scene(scene_name) -> void:
	current_scene = scene_name
	get_tree().change_scene_to_packed(scenes[scene_name][0])
	if $AudioStreamPlayer.stream != scenes[scene_name][1] && music_enabled:
		$AudioStreamPlayer.stream = scenes[scene_name][1]
		$AudioStreamPlayer.play()
