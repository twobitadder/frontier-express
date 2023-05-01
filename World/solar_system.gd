extends Node2D

@onready var game_ui: CanvasLayer = $CanvasLayer
@onready var job_manager: Node = $JobManager
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	job_manager.new_job.connect(game_ui.incoming_job)
	job_manager.loading.connect(player._on_loading)
	game_ui.job_created.connect(job_manager._on_new_job_listing)
	player.load_complete.connect(job_manager._on_load_complete)
	player.health_changed.connect(game_ui._on_health_changed)
	player.cargo_changed.connect(game_ui._on_cargo_changed)
	
	for planet in get_tree().get_nodes_in_group("Planets"):
		if planet.planet_name == "Sun":
			continue
		planet.entered_radius.connect(job_manager._on_planet_approach)
	
	GameState.dialog_request(GameState.actors.ShipBoard, "Hold TAB to view your pending jobs")
	GameState.dialog_request(GameState.actors.ShipBoard, "You can accept or deny the job with Y/N keys")
	GameState.dialog_request(GameState.actors.ShipBoard, "Be careful! Rejecting jobs or letting them expire...")
	GameState.dialog_request(GameState.actors.ShipBoard, "will be counted against you! 5 strikes and it's gameover!")
