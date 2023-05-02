extends Node2D

signal sun_proximity(active)

const sun_warnings := [
	"WARNING TOO CLOSE TO THE SUN! TURN BACK!!",
	"OH NO IT'S SO HOT AAAA",
	"THE SHIP IS MELTING THIS IS NOT GOOD",
	"Friendly reminder that tHE SUN IS A BALL OF FIRE",
	"Seems toasty...  OH PLEASE TURN BACK"
]

const planet_number : int = 0
const planet_name : String = "Sun"
const sun_damage : float = 5.0

var player : CharacterBody2D
var damaging_player := false

@onready var planet_position := global_position

func _process(delta: float) -> void:
	$Area2D/Sprite2D2.rotation += 0.05 * delta
	if damaging_player:
		player.hurt(sun_damage * delta, true)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group(&"Player"):
		return
	$AudioStreamPlayer.play()
	GameState.dialog_request(GameState.actors.ShipBoard, sun_warnings[randi() % sun_warnings.size()])
	sun_proximity.emit(true)
	player = body
	damaging_player = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if !body.is_in_group(&"Player"):
		return
	$AudioStreamPlayer.stop()
	sun_proximity.emit(false)
	damaging_player = false


func _on_area_2d_area_entered(area: Area2D) -> void:
	if !area.is_in_group(&"Enemies"):
		return
	area.die()
