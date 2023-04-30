class_name JobManager
extends Node

signal new_job(job : Job)
signal loading(jobs, state)
signal job_failed(job : Job)
signal job_completed(job : Job)

enum STATUS { COMPLETED, PENDING, ACTIVE, TRANSIT, EXPIRED, REFUSED, IGNORED }

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

func create_job() -> void:
	var job = Job.new()
	var origin_ind = randi_range(0, planet_list.size() - 1)
	var dest_ind = origin_ind
	while dest_ind == origin_ind:
		dest_ind = randi_range(0, planet_list.size() - 1)
	
	job.id = job_id_counter
	job.origin = planet_list[origin_ind]
	job.destination = planet_list[dest_ind]
	job.completion_time = 240
	job.accept_time = 10
	job.payout = 200
	job.size = 1
	
	pending_job_list.append(job)
	job_id_counter += 1
	new_job.emit(job)

func _on_timer_timeout() -> void:
	create_job()

func _on_new_job_listing(listing) -> void:
	listing.job_ended.connect(_on_job_ended)
	listing.job_accepted.connect(_on_job_accepted)

func _on_job_ended(job) -> void:
	match job.status:
		STATUS.IGNORED:
			pending_job_list.erase(job)
		STATUS.REFUSED:
			pending_job_list.erase(job)
		STATUS.EXPIRED:
			active_job_list.erase(job)
			job_failed.emit(job)
		STATUS.TRANSIT:
			active_job_list.erase(job)
			job_failed.emit(job)
		STATUS.COMPLETED:
			active_job_list.erase(job)
			job_completed.emit(job)
			

func _on_job_accepted(job) -> void:
	pending_job_list.erase(job)
	active_job_list.append(job)

func _on_planet_approach(planet_name, approaching) -> void:
	print("approaching")
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
