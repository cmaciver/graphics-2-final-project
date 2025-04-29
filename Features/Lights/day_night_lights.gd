extends Node3D

@export var start_time = 6.0
@export var hours_per_second = 1.0

func _ready():
	$AnimationPlayer.speed_scale = hours_per_second
	$AnimationPlayer.seek(start_time)
