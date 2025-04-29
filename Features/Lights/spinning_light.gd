extends Node3D

@onready var light = $DirectionalLight3D
@export var speed : float = 1.0

func _process(delta: float) -> void:
	light.rotation.y += delta * speed
	
