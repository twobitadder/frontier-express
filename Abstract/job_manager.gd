class_name JobManager
extends Node

signal new_job(job : Job)
signal loading(jobs, state)
signal job_failed(job : Job)
signal job_completed(job : Job)

var job_complete_sound = preload("res://Assets/Sounds/LittleReward.wav")
var job_timed_out_sound = preload("res://Assets/Sounds/LittleFallingDown.wav")
var new_job_sound = preload("res://Assets/Sounds/GetAPowerUp.wav")

const MAX_JOB_TIME = 240.0
const MIN_JOB_TIME = 75.0
const MIN_JOB_REFRESH_TIME = 20.0
const MAX_JOB_REFRESH_TIME = 50.0

const deliver_request_bodies = [
	"I need this sent to %s, ASAP!...

... Please",
	"I've got a vital shipment to %s for you, good luck!",
	"Please ensure this gets to %s, they need it badly!",
	"My cat is very lonely. Please deliver this care package to them on %s",
	"I'm BORED so I'm MAILING SOMETHING please go to %s!!",
	"You ever wondered what the point of life is? Anyway I need this to %s",
	"Got this package due for %s, it's marked urgent!",
	"If this doesn't get to %s it will be a catastrophe!!"
]

enum STATUS { COMPLETED, PENDING, ACTIVE, TRANSIT, EXPIRED, REFUSED, IGNORED }

@onready var timer: Timer = $Timer

var cost_array = [
	100,
	75,
	50,
	25,
	25,
	40
]

var planet_list : Array
var pending_job_list : Array
var active_job_list : Array
var job_id_counter := 0

class Job:
	var id
	var origin
	var destination
	var completion_time
	var accept_time
	var payout
	var size
	var status = STATUS.PENDING
	var listing

func _ready() -> void:
	randomize()
	planet_list = get_tree().get_nodes_in_group("Planets")
	
	#filter out the sun we don't want jobs to go there lol
	planet_list = planet_list.filter(func(planet): return planet.planet_name != "Sun")
	
	pending_job_list = Array()
	active_job_list = Array()
	
	await get_tree().create_timer(3).timeout
	create_job(planet_list[4], planet_list[3], 40.0)
	timer.start(MAX_JOB_REFRESH_TIME)


func create_job(_origin = null, _destination = null, wait_time = 0.0) -> void:
	var job = Job.new()
	if !_origin:
		var origin_ind = randi_range(0, planet_list.size() - 1)
		job.origin = planet_list[origin_ind]
	else:
		job.origin = _origin
	if !_destination:
		var origin_ind = planet_list.find(job.origin)
		var dest_ind = origin_ind
		while dest_ind == origin_ind:
			dest_ind = randi_range(0, planet_list.size() - 1)
		job.destination = planet_list[dest_ind]
	else:
		job.destination = _destination
	
	job.id = job_id_counter
	job.completion_time = remap(GameState.time_counter, 0.0, GameState.MAX_DIFFICULTY_TIME_LIMIT, MAX_JOB_TIME, MIN_JOB_TIME)
	job.accept_time = 10.0 if wait_time == 0.0 else wait_time
	job.size = randi_range(1, 3)
	job = calculate_payout(job)
	
	pending_job_list.append(job)
	job_id_counter += 1
	new_job.emit(job)

func calculate_payout(job : Job) -> Job:
	var job_cost := 0.0
	job_cost += cost_array[planet_list.find(job.origin)]
	job_cost += cost_array[planet_list.find(job.destination)]
	job_cost += 0.05 * (job.origin.planet_position.distance_to(job.destination.planet_position))
	job_cost *= job.size
	job_cost *= remap(job.completion_time, MAX_JOB_TIME, MIN_JOB_TIME, 1.0, 2.5)
	job.payout = int(job_cost)
	return job

func _on_timer_timeout() -> void:
	GameState.dialog_request(GameState.actors.ShipBoard, "New job pending")
	create_job()
	timer.start(remap(GameState.time_counter, 0.0, GameState.MAX_DIFFICULTY_TIME_LIMIT, MIN_JOB_REFRESH_TIME, MAX_JOB_REFRESH_TIME))

func _on_new_job_listing(listing) -> void:
	spawn_sound(new_job_sound)
	listing.job_ended.connect(_on_job_ended)
	listing.job_accepted.connect(_on_job_accepted)

func spawn_sound(resource) -> void:
	var new_sound = AudioStreamPlayer.new()
	new_sound.stream = resource
	new_sound.volume_db = -10.0
	add_child(new_sound)
	new_sound.finished.connect(new_sound.queue_free)
	new_sound.play()

func _on_job_ended(job) -> void:
	match job.status:
		STATUS.IGNORED:
			spawn_sound(job_timed_out_sound)
			pending_job_list.erase(job)
		STATUS.REFUSED:
			pending_job_list.erase(job)
		STATUS.EXPIRED:
			spawn_sound(job_timed_out_sound)
			active_job_list.erase(job)
			job_failed.emit(job)
		STATUS.TRANSIT:
			spawn_sound(job_timed_out_sound)
			active_job_list.erase(job)
			job_failed.emit(job)
		STATUS.COMPLETED:
			spawn_sound(job_complete_sound)
			active_job_list.erase(job)
			job_completed.emit(job)
			GameState.completed_jobs += 1
			

func _on_job_accepted(job) -> void:
	pending_job_list.erase(job)
	active_job_list.append(job)
	build_dialog_request(job)

func build_dialog_request(job) -> void:
	var dialog = deliver_request_bodies[randi() % deliver_request_bodies.size()] % job.destination.planet_name
	GameState.dialog_request(GameState.actors[job.origin.planet_name], dialog)

func _on_planet_approach(planet_name, approaching) -> void:
	if !approaching:
		loading.emit([], planet_name, approaching)
		return
	
	var relevant_jobs = active_job_list.filter(func(job): return job.origin.planet_name == planet_name || job.destination.planet_name == planet_name)
	
	if relevant_jobs.size() == 0:
		return
	
	loading.emit(relevant_jobs, planet_name, approaching)

func _on_load_complete(job) -> void:
	if job.status == STATUS.ACTIVE:
		job.listing.change_job_status(STATUS.TRANSIT)
	elif job.status == STATUS.TRANSIT:
		job.listing.change_job_status(STATUS.COMPLETED)
		GameState.dialog_request(GameState.actors.ShipBoard, "Delivery complete! $%s deposited" % job.payout)
