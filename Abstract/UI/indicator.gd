extends Node2D

var planet : Node2D
var player : CharacterBody2D

func _ready() -> void:
	$Sprite2D/Label.text = str(planet.planet_number) if planet.planet_number > 0 else "S"

func _process(_delta) -> void:
	look_at(planet.planet_position)
	$Sprite2D.position.x = remap(player.global_position.distance_to(planet.planet_position), 1000, 0, 30, 2)
