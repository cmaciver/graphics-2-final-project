@icon("res://_ico/DirectionalLight3D.svg")
extends Node3D

@export var start_time = 6.0 #:
	#set(value):
		#start_time = value
		#$AnimationPlayer.seek(start_time)
		
@export var hours_per_second = 0.4

func _ready():
	$AnimationPlayer.speed_scale = hours_per_second
	$AnimationPlayer.seek(start_time)
