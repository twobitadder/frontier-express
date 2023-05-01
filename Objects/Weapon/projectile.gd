extends Area2D

var speed = 300.0


func _physics_process(delta: float) -> void:
	position += (Vector2.RIGHT * speed * delta).rotated(rotation)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"Enemies"):
		area.hurt()
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"Player"):
		body.hurt(5.0)
		queue_free()
