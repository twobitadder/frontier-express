extends Node

signal strikes_updated(strikes)
signal money_updated(money)
signal new_dialog(actor, dialog)
signal gameover

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
		strikes = value
		if strikes == 0:
			gameover.emit()

var money : int = 0:
	get:
		return money
	set(value):
		money_updated.emit(value)
		money = value


var pending_dialog := Array()
var processing_dialog := false

func _process(_delta) -> void:
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
