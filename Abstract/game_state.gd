extends Node

signal strikes_updated(strikes)
signal money_updated(money)
signal gameover

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

