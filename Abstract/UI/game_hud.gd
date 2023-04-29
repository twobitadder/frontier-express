extends CanvasLayer

signal job_created(listing)

var listing_scene = preload("res://Abstract/UI/JobListing.tscn")

@onready var resume: Button = %Resume
@onready var quit: Button = %Quit
@onready var active_jobs: Control = %ActiveJobs
@onready var pending_jobs: Control = %PendingJobs
@onready var jobs_list: PanelContainer = %JobsList
@onready var money: Label = %Money
@onready var health_progress: ProgressBar = %HealthProgress
@onready var energy_progress: ProgressBar = %EnergyProgress
@onready var comms: PanelContainer = %Comms
@onready var jobs_label: Label = %JobsLabel
@onready var job_listings: VBoxContainer = %JobListings

var pending_jobs_amt := 0
var selected_job : JobListing


var comms_positions := { "inactive" : Vector2(111, 242),\
						"active" : Vector2(111, 188)}

var jobs_positions := {"inactive" : Vector2(-100, 0),\
						"active" : Vector2.ZERO}

func _ready() -> void:
	jobs_list.position = jobs_positions.inactive
	comms.position = comms_positions.inactive

func pause(state : bool) -> void:
	get_tree().paused = state
	if state:
		$PauseMenu.show()
	else:
		$PauseMenu.hide()

func _input(event) -> void:
	if event.is_action_pressed("check_job_board"):
		jobs_list_move(true)
	elif event.is_action_released("check_job_board"):
		jobs_list_move(false)

	if event.is_action_pressed(&"y") && is_instance_valid(selected_job):
		selected_job.change_job_status(JobManager.STATUS.ACTIVE)
		accept_job()
		update_selected_job()
	elif event.is_action_pressed(&"n") && is_instance_valid(selected_job):
		selected_job.change_job_status(JobManager.STATUS.REFUSED)
		update_selected_job()

func update_selected_job() -> void:
	#get the next pending job to listen to y/n prompts when you accept or refuse a job
	
	var listings = job_listings.get_children().filter(func(child): return child.get_index() > pending_jobs.get_index())
	if listings.size() > 0:
		selected_job = listings.front()

func accept_job() -> void:
	job_listings.remove_child(selected_job)
	active_jobs.add_sibling(selected_job)
	selected_job.timer.start(selected_job.time_left)
	selected_job.job_accepted.emit(selected_job.job)

func _on_resume_pressed() -> void:
	pause(false)

func _on_quit_pressed() -> void:
	get_tree().quit()

func jobs_list_move(activate : bool) -> void:
	var new_pos = jobs_positions.active if activate else jobs_positions.inactive
	await create_tween().tween_property(jobs_list, "position", new_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).finished
	if activate:
		pending_jobs_amt = 0
		jobs_label.text = "Jobs"

func comms_move(activate : bool) -> void:
	var new_pos = comms_positions.active if activate else comms_positions.inactive
	await create_tween().tween_property(comms, "position", new_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).finished

func incoming_job(job) -> void:
	pending_jobs_amt += 1
	
	var new_job = listing_scene.instantiate()
	pending_jobs.add_sibling(new_job)
	new_job.setup(job)
	selected_job = new_job
	job_created.emit(new_job)
	
	var tween = create_tween()
	tween.tween_property(jobs_label, "position:y", jobs_label.position.y + 5, 0.1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(jobs_label, "position:y", jobs_label.position.y, 0.1).set_trans(Tween.TRANS_BOUNCE)
	jobs_label.text = "Jobs (%s)" % pending_jobs_amt
