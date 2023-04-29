extends Sprite2D

@export var nebula_1_color : Color
@export var nebula_2_color : Color
@export var threshold_1 : float
@export var threshold_2 : float

func _ready() -> void:
	if nebula_1_color != Color.BLACK:
		material.set_shader_parameter(&"nebula_1", nebula_1_color)
	if nebula_2_color != Color.BLACK:
		material.set_shader_parameter(&"nebula_2", nebula_2_color)
	if !is_zero_approx(threshold_1):
		material.set_shader_parameter(&"threshold_1", threshold_1)
	if !is_zero_approx(threshold_2):
		material.set_shader_parameter(&"threshold_2", threshold_2)
