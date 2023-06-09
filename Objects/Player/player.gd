extends CharacterBody2D

signal load_cancelled
signal load_complete(job)
signal health_changed(health)
signal energy_changed(energy)
signal cargo_changed(cargo)
signal dead
signal cargo_insufficient

const SIZE_MULTIPLIER := 50.0

enum STATE { LOADING, UNLOADING, IDLE }

var indicator = preload("res://Abstract/UI/Indicator.tscn")
var bullet_scene = preload("res://Objects/Weapon/Projectile.tscn")
var shot_resource = preload("res://Assets/Sounds/LaserAttackMini.wav")

@onready var load_progress: ProgressBar = $LoadIndicatorRotation/LoadProgress
@onready var thrust_particles: Node2D = $ThrustParticles
@onready var shoot_timer: Timer = $ShootTimer
@onready var camera_2d: Camera2D = $Camera2D
@onready var death_particles: Node2D = $DeathParticles
@onready var thrust: AudioStreamPlayer = $Thrust

@export var shake_decay := 5.0
@export var acceleration := 50.0
@export var turn_speed := 5.0
@export var max_speed := 150.0
@export var load_rate := 50.0
@export var shot_cooldown := 0.2

@export var cargo := 4:
	get:
		return cargo
	set(value):
		cargo_changed.emit(value)
		cargo = value

@export var energy := 1000.0 :
	get:
		return energy
	set(value):
		energy_changed.emit(value)
		energy = value

@export var health := 100.0:
	get:
		return health
	set(value):
		health_changed.emit(health)
		health = min(value, 100.0)
		if health <= 0.0:
			die()
			dead.emit()

var current_job : JobManager.Job
var pending_local_jobs : Array
var local_planet : String:
	get:
		return local_planet
	set(value):
		local_planet = value
var loading_state := STATE.IDLE
var bullet_container : Node2D
var nearby_enemies := Array()
var current_shake_strength := 0.0
var is_dead := false
var retry_loading := true


func _ready() -> void:
	var planets = get_tree().get_nodes_in_group(&"Planets")
	bullet_container = get_tree().get_nodes_in_group(&"BulletContainer")[0]
	for particles in death_particles.get_children():
		pass
	for planet in planets:
		var ind = indicator.instantiate()
		ind.planet = planet
		ind.player = self
		$Indicators.add_child(ind)

func _physics_process(delta: float) -> void:
	process_screen_shake(delta)
	
	if is_dead:
		return
	
	var input = Input.get_vector(&"ctrclockwise", &"clockwise", &"back", &"forward")
	
	rotation_degrees += turn_speed * input.x
	velocity += (Vector2.RIGHT * max(input.y, 0.0) * acceleration * delta).rotated(rotation)
	thrust.playing = true if input.y > 0 else false
	velocity = velocity.limit_length(max_speed)
	$LoadIndicatorRotation.global_rotation = 0.0
	
	if Input.is_action_just_pressed(&"shoot") && shoot_timer.is_stopped():
		shoot()
	
	
	process_pending_jobs(delta)
	
	particles_visible(input.y > 0)
	move_and_slide()

func process_pending_jobs(delta) -> void:
	if pending_local_jobs.size() == 0 || local_planet == "" || !retry_loading:
		return
	
	
	#holy christ ugly code hoooo
	if current_job == null:
		#prioritize unloading
		for job in pending_local_jobs:
			if job.destination.planet_name == local_planet && job.status == JobManager.STATUS.TRANSIT:
				current_job = job
				change_loading_state(STATE.UNLOADING)
				break
		
		#ugly to loop twice but easier i suppose
		if current_job == null:
			var origin_jobs = pending_local_jobs.filter(func(job): return job.origin.planet_name == local_planet)
			if origin_jobs.size() == 0:
				return
			origin_jobs.sort_custom(func(a, b): return a.size > b.size)
			for job in origin_jobs:
				if job.status == JobManager.STATUS.ACTIVE && job.size <= cargo:
					current_job = job
					change_loading_state(STATE.LOADING)
					break
			
			#if we still haven't found a job that means likely that we do not have the cargo space
			if current_job == null:
				cargo_insufficient.emit()
				GameState.dialog_request(GameState.actors.ShipBoard, "Looks like you don't have enough space to load this! Unload other jobs!")
				retry_loading = false
	
	match loading_state:
		STATE.LOADING, STATE.UNLOADING:
			load_progress.value += load_rate * delta
		STATE.IDLE:
			pass

func process_screen_shake(delta) -> void:
	current_shake_strength = lerpf(current_shake_strength, 0.0, shake_decay * delta)
	camera_2d.offset = Vector2(
		randf_range(-current_shake_strength, current_shake_strength),
		randf_range(-current_shake_strength, current_shake_strength)
	)

func add_screen_shake(value) -> void:
	if value > current_shake_strength && current_shake_strength < 15.0:
		current_shake_strength = value

func change_loading_state(state) -> void:
	match state:
		STATE.LOADING, STATE.UNLOADING:
			_setup_loading()
		STATE.IDLE:
			_reset_loading_progress()
			current_job = null
	loading_state = state

func _setup_loading() -> void:
	$LoadingStart.play()
	if current_job == null:
		printerr("current job is null but we're trying to load - we absolutely should not be here")
		return
	load_progress.show()
	load_progress.max_value = current_job.size * SIZE_MULTIPLIER

func _on_loading(jobs, planet_name, approaching) -> void:
	if is_dead:
		return
		
	if !approaching:
		retry_loading = true
		local_planet = ""
		pending_local_jobs.clear()
		if loading_state in [STATE.LOADING, STATE.UNLOADING]:
			load_cancelled.emit()
			change_loading_state(STATE.IDLE)
		return
	
	pending_local_jobs = jobs
	local_planet = planet_name

func _reset_loading_progress() -> void:
	if !load_progress.visible:
		return
	
	load_progress.value = 0
	load_progress.hide()

func _on_load_progress_value_changed(value: float) -> void:
	if value != load_progress.max_value:
		return
	
	if current_job.status == JobManager.STATUS.ACTIVE:
		cargo -= current_job.size
	elif current_job.status == JobManager.STATUS.TRANSIT:
		cargo += current_job.size
	
	pending_local_jobs.erase(current_job)
	load_complete.emit(current_job)
	retry_loading = true
	$LoadingComplete.play()
	change_loading_state(STATE.IDLE)

func particles_visible(vis) -> void:
	for child in thrust_particles.get_children():
		child.emitting = vis

func hurt(value, is_from_sun) -> void:
	if is_dead:
		return
	
	health -= value
	add_screen_shake(0.5 if !is_from_sun else 1.5)

func shoot() -> void:
	var bullet = bullet_scene.instantiate()
	bullet_container.add_child(bullet)
	bullet.global_position = global_position
	if nearby_enemies.size() > 0:
		bullet.look_at(nearby_enemies.front().global_position)
	else:
		bullet.global_rotation = global_rotation
	bullet.set_collision_mask_value(1, false)
	bullet.set_collision_mask_value(2, true)
	var shot_sound = AudioStreamPlayer.new()
	shot_sound.stream = shot_resource
	shot_sound.volume_db = -15
	shot_sound.finished.connect(shot_sound.queue_free)
	add_child(shot_sound)
	shot_sound.play()
	shoot_timer.start(shot_cooldown)

func _on_shoot_timer_timeout() -> void:
	if is_dead:
		return
	
	if Input.is_action_pressed(&"shoot"):
		shoot()

func die() -> void:
	is_dead = true
	set_collision_layer_value(1, false)
	$Sprite2D.hide()
	add_screen_shake(10.0)
	for child in death_particles.get_children():
		child.emitting = true
	$DeathSound.play()
	await get_tree().create_timer(1).timeout
	SceneHandler.change_scene("Game Over")

func _on_aim_helper_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	
	if area.is_in_group(&"Enemies") && !nearby_enemies.has(area):
		nearby_enemies.append(area)
		nearby_enemies.sort_custom(func(a,b): return global_position.distance_squared_to(a.global_position) > global_position.distance_squared_to(b.global_position))


func _on_aim_helper_area_exited(area: Area2D) -> void:
	if is_dead:
		return
	
	if !area.is_in_group(&"Enemies") || !nearby_enemies.has(area):
		return
	nearby_enemies.erase(area)
