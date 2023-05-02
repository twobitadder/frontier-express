extends Node

signal enemies_spawning

const MIN_SPAWN_MIN := 10.0
const MIN_SPAWN_MAX := 50.0
const MAX_SPAWN_MIN := 30.0
const MAX_SPAWN_MAX := 60.0

const enemies_spawned_messages = [
	"Got some drones incoming!",
	"Bogies pinged on radar",
	"Got more fun incoming!",
	"It's getting a little busier!",
	"Hope your trigger finger is warmed up!",
	"More drones? Uuuugh",
	"Oh good I felt like getting shot at"
]

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
	GameState.dialog_request(GameState.actors.ShipBoard, enemies_spawned_messages[randi() % enemies_spawned_messages.size()])
	$AudioStreamPlayer.play()
	for i in randi_range(min_enemy, max_enemy):
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
	var min_spawn = remap(GameState.time_counter, 0.0, GameState.MAX_DIFFICULTY_TIME_LIMIT, MIN_SPAWN_MAX, MIN_SPAWN_MIN)
	var max_spawn = remap(GameState.time_counter, 0.0, GameState.MAX_DIFFICULTY_TIME_LIMIT, MAX_SPAWN_MAX, MAX_SPAWN_MIN)
	timer.start(randf_range(min_spawn, max_spawn))

func cleanup(enemy) -> void:
	if !enemies.has(enemy):
		printerr("trying to erase an enemy after it has already been erased")
		return
	
	enemies.erase(enemy)
