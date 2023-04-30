extends Node2D

@onready var game_ui: CanvasLayer = $CanvasLayer
@onready var job_manager: Node = $JobManager
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	job_manager.new_job.connect(game_ui.incoming_job)
	job_manager.loading.connect(player._on_loading)
	game_ui.job_created.connect(job_manager._on_new_job_listing)
	player.load_complete.connect(job_manager._on_load_complete)
	
	for planet in get_tree().get_nodes_in_group("Planets"):
		if planet.planet_name == "Sun":
			continue
		planet.entered_radius.connect(job_manager._on_planet_approach)
