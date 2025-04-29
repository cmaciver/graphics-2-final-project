class_name WaterPlane
extends MeshInstance3D

func _process(delta):
	mesh.material.set_shader_parameter("movement_direction", RenderGlobals.wind_direction)
	mesh.material.set_shader_parameter("movement_strength", RenderGlobals.wind_strength)
