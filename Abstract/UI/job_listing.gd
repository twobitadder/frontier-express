class_name JobListing
extends VBoxContainer

signal job_ended(job)
signal job_accepted(job)

@export var time_left := 240

@onready var time_display : ProgressBar = $ProgressBar
@onready var origin: TextureRect = %Origin
@onready var origin_number: Label = %OriginNumber
@onready var destination: TextureRect = %Destination
@onready var destination_number: Label = %DestinationNumber
@onready var timer: Timer = $Timer
@onready var status_label: Label = %StatusLabel

var job : JobManager.Job

var stylebox : StyleBoxFlat

func setup(_job) -> void:
	job = _job
	origin.texture = load(job.origin.planet_image)
	origin_number.text = "%s" % job.origin.planet_number
	destination.texture = load(job.destination.planet_image)
	destination_number.text = "%s" % job.destination.planet_number
	time_left = job.accept_time
	timer.start(time_left)

func _ready() -> void:
	stylebox = time_display.get_theme_stylebox(&"fill").duplicate()

func _process(_delta) -> void:
	time_display.value = remap(timer.time_left, time_left, 0.0, time_display.max_value, time_display.min_value)
	stylebox.bg_color = Color.DARK_GREEN.lerp(Color.RED, inverse_lerp(time_display.max_value, time_display.min_value, time_display.value))
	time_display.add_theme_stylebox_override(&"fill", stylebox)


func change_job_status(status : JobManager.STATUS) -> void:
	job.status = status
	match job.status:
		JobManager.STATUS.REFUSED:
			status_label.text = "Job declined!"
			_on_timer_timeout()
		JobManager.STATUS.ACTIVE:
			status_label.text = "Pick up cargo!"
			time_left = job.completion_time
		JobManager.STATUS.TRANSIT:
			status_label.text = "Cargo on board!"
		JobManager.STATUS.COMPLETED:
			status_label.text = "Well done!"

func _on_timer_timeout() -> void:
	match job.status:
		JobManager.STATUS.PENDING:
			job.status = JobManager.STATUS.IGNORED
			status_label.text = "Timed out!"
		JobManager.STATUS.ACTIVE:
			job.status = JobManager.STATUS.EXPIRED
			status_label.text = "Timed out!"
	
	await create_tween().tween_property(self, "position:x", -100.0, 1.5).set_trans(Tween.TRANS_ELASTIC).finished
	job_ended.emit(job)
	queue_free() 
