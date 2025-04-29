@icon("res://_ico/Camera3D.svg")
extends Node3D

@onready var camera = $Camera3D

@export var SPEED : float = 0.5
@export var DIRECTION := Vector3.ZERO

func _process(delta):
	position += DIRECTION * delta
