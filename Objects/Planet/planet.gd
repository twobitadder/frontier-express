extends Node2D

signal entered_radius(p_name, entered)

@export_file var planet_image
@export var planet_name : String
@export var orbit_speed := 0.2
@export var planet_number := 0
@export var orbit_length := 0.0

var planet_position : Vector2

func _ready() -> void:
	$Area2D.position.x = orbit_length
	if (planet_image):
		$Area2D/Sprite2D.texture = load(planet_image)
	rotation = randf() * 2 * PI
	planet_position = $Area2D.global_position

func _physics_process(delta) -> void:
	rotation += (orbit_speed * delta)
	$Area2D.global_rotation = 0.0
	planet_position = $Area2D.global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	entered_radius.emit(planet_name, true)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name != "Player":
		return
	entered_radius.emit(planet_name, false)
