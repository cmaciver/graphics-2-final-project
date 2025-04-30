@icon("res://_ico/Camera3D.svg")
extends Node3D

@onready var camera = $Camera3D

var angle = 0
@export var SPEED : float = 0.5
@export var RADIUS : float = 7.0
@export var Y : float = 5.0


func _process(delta : float) -> void:
	angle += delta * SPEED
	
	camera.position = (RADIUS*Vector3.RIGHT + Vector3.UP*Y).rotated(Vector3.UP, angle)
	camera.look_at(position)
	
