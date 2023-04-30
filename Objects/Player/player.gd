extends CharacterBody2D

signal load_cancelled
signal load_complete(job)

const SIZE_MULTIPLIER := 50.0

enum STATE { LOADING, UNLOADING, IDLE }

var indicator = preload("res://Abstract/UI/Indicator.tscn")

@onready var load_progress: ProgressBar = $LoadProgress

@export var acceleration := 50.0
@export var turn_speed := 5.0
@export var max_speed := 150.0
@export var load_rate := 50.0

var current_job : JobManager.Job
var pending_local_jobs : Array
var local_planet : String
var loading_state := STATE.IDLE

func _ready() -> void:
	var planets = get_tree().get_nodes_in_group("Planets")
	for planet in planets:
		var ind = indicator.instantiate()
		ind.planet = planet
		$Indicators.add_child(ind)

func _physics_process(delta: float) -> void:
	var input = Input.get_vector(&"ctrclockwise", &"clockwise", &"back", &"forward")
	
	rotation_degrees += turn_speed * input.x
	velocity += (Vector2.RIGHT * input.y * acceleration * delta).rotated(rotation)
	velocity = velocity.limit_length(max_speed)
	
	process_pending_jobs(delta)
	
	move_and_slide()

func process_pending_jobs(delta) -> void:
	if pending_local_jobs.size() == 0 || local_planet == "":
		return
	
	
	#holy christ ugly code hoooo
	if current_job == null:
		#prioritize unloading
		for job in pending_local_jobs:
			if job.destination.planet_name == local_planet:
				current_job = job
				change_loading_state(STATE.UNLOADING)
				break
		
		#ugly to loop twice but easier i suppose
		if current_job == null:
			for job in pending_local_jobs:
				if job.origin.planet_name == local_planet:
					current_job = job
					change_loading_state(STATE.LOADING)
					break
	
	match loading_state:
		STATE.LOADING, STATE.UNLOADING:
			load_progress.value += load_rate * delta
		STATE.IDLE:
			pass

func change_loading_state(state) -> void:
	match state:
		STATE.LOADING, STATE.UNLOADING:
			_setup_loading()
		STATE.IDLE:
			_cancel_loading()
			current_job = null
	loading_state = state

func _setup_loading() -> void:
	if current_job == null:
		printerr("current job is null but we're trying to load - we absolutely should not be here")
		return
	load_progress.show()
	load_progress.max_value = current_job.size * SIZE_MULTIPLIER

func _on_loading(jobs, planet_name, approaching) -> void:
	if !approaching:
		pending_local_jobs.clear()
		change_loading_state(STATE.IDLE)
		return
	
	pending_local_jobs = jobs
	local_planet = planet_name

func _cancel_loading() -> void:
	if !load_progress.visible:
		return
	
	local_planet = ""
	load_progress.value = 0
	load_progress.hide()
	load_cancelled.emit()

func _on_load_progress_value_changed(value: float) -> void:
	if value != load_progress.max_value:
		return
	
	pending_local_jobs.erase(current_job)
	load_complete.emit(current_job)
	change_loading_state(STATE.IDLE)
