extends Node

signal strikes_updated(strikes)
signal money_updated(money)
signal new_dialog(actor, dialog)
signal gameover

const MAX_DIFFICULTY_TIME_LIMIT = 600.0

#lol the values and keys are the same so this data is autocompleted
const actors = {
	"Cornucopia" : "Cornucopia",
	"Fire Pearl" : "FirePearl",
	"Foundation" : "Foundation",
	"Harvard's End" : "HarvardsEnd",
	"ShipBoard" : "ShipBoard",
	"Taxila" : "Taxila",
	"Vesper" : "Vesper"
}

class DialogObject:
	var actor : String
	var dialog : String

var strikes : int = 5:
	get:
		return strikes
	set(value):
		strikes_updated.emit(value)
		strikes = min(value, 5)
		if strikes == 0:
			gameover.emit()
			SceneHandler.change_scene("Game Over")

var money : int = 0:
	get:
		return money
	set(value):
		money_updated.emit(value)
		money = value

var completed_jobs : int = 0:
	get:
		return completed_jobs
	set(value):
		if value % 5 == 0:
			strikes += 1
			get_tree().get_first_node_in_group(&"Player").health += 20
			dialog_request(actors.ShipBoard, "Good news! You've gained another chance with the system!")
		completed_jobs = value

var pending_dialog := Array()
var processing_dialog := false
var time_counter := 0.0

func _process(delta) -> void:
	time_counter += delta
	if pending_dialog.size() > 0 && !processing_dialog:
		processing_dialog = true
		new_dialog.emit(pending_dialog.front().actor, pending_dialog.front().dialog)

func _on_dialog_completed() -> void:
	pending_dialog.pop_front()
	processing_dialog = false

func dialog_request(actor, dialog) -> void:
	var dialog_object = DialogObject.new()
	dialog_object.actor = actor
	dialog_object.dialog = dialog
	pending_dialog.append(dialog_object)

func reset() -> void:
	pending_dialog.clear()
	processing_dialog = false
	time_counter = 0.0
	money = 0
	strikes = 5
	completed_jobs = 0
