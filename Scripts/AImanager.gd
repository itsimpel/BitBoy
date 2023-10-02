extends Node2D

var leeched = false
var health = 5

func _damage(double):
	health -= 1
	if double:
		health -= 1
