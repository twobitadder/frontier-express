extends Area2D

var impact_effect = preload("res://Objects/Weapon/WeaponImpact.tscn")
var impact_sound = preload("res://Objects/Weapon/HitSound.tscn")

@onready var bullet_container = get_tree().get_nodes_in_group(&"BulletContainer")[0]

var speed = 300.0

func _physics_process(delta: float) -> void:
	position += (Vector2.RIGHT * speed * delta).rotated(rotation)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"Enemies"):
		area.hurt(Vector2.RIGHT.rotated(rotation))
		var impact = impact_effect.instantiate()
		bullet_container.add_child(impact)
		impact.global_position = global_position
		var sound = impact_sound.instantiate()
		bullet_container.add_child(sound)
		sound.global_position = global_position
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"Player"):
		body.hurt(5.0, false)
		var impact = impact_effect.instantiate()
		bullet_container.add_child(impact)
		impact.global_position = global_position
		var sound = impact_sound.instantiate()
		bullet_container.add_child(sound)
		sound.global_position = global_position
		queue_free()
