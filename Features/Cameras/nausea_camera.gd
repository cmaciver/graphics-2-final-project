@icon("res://_ico/Camera3D.svg")
extends Node3D

@onready var camera = $Camera3D

var angle = 0
@export var SPEED : float = 2.0
@export var FOCUS_ORIGIN := true
@export var FOCUS_DIST : float = 80.0

func _process(delta : float) -> void:
	angle += delta * SPEED
	
	camera.position = Vector3.RIGHT.rotated(Vector3.BACK, angle)
	camera.look_at(
		Vector3.ZERO if FOCUS_ORIGIN else position + Vector3.FORWARD * FOCUS_DIST,
		Vector3.UP
	)
	
