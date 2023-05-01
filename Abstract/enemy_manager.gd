extends Node

signal enemies_spawning

var enemy_scene = preload("res://Objects/Enemy/Enemy.tscn")

@export var min_enemy := 2
@export var max_enemy := 5

@onready var timer: Timer = $Timer

var enemy_spawners : Array
var enemy_container : Node2D
var enemies := Array()

func _ready() -> void:
	enemy_spawners = get_tree().get_nodes_in_group(&"EnemySpawner")
	enemy_container = get_tree().get_nodes_in_group(&"EnemyContainer")[0]

func setup_enemy():
	enemies_spawning.emit()
	enemy_spawners.shuffle()
	var spawn_point = enemy_spawners.front()
	for i in randi_range(min_enemy, max_enemy):
		print("spawning enemy %s" % str(i))
		var enemy = enemy_scene.instantiate()
		enemy.manager = self
		enemy_container.add_child(enemy)
		enemy.global_position = spawn_point.global_position
		enemies.append(enemy)
	
	if randf() > 0.75:
		var pick = randi() % 2
		if pick == 0 && min_enemy < max_enemy:
			min_enemy += 1
		else:
			max_enemy += 1

func _on_timer_timeout() -> void:
	setup_enemy()
	timer.start(randf_range(10, 30))

func cleanup(enemy) -> void:
	if !enemies.has(enemy):
		printerr("trying to erase an enemy after it has already been erased")
		return
	
	enemies.erase(enemy)
