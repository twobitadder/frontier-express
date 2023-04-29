extends Node2D

var planet : Node2D

func _ready() -> void:
	$Sprite2D/Label.text = str(planet.planet_number) if planet.planet_number > 0 else "S"

func _process(_delta) -> void:
	look_at(planet.planet_position)
