@tool
extends Node3D

@export_tool_button("Generate Foliage") var generate_button = scatter_points

var foliage_class = preload("res://Scenes/foliage.tscn")

var terrain : TerrainGenerator
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	terrain = $"../Terrain Generation"
	rng.seed = Time.get_ticks_usec()
	scatter_points()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func scatter_points(count = 10):
	for child in get_children():
		child.queue_free()
	
	for i in count:
		var new_foliage = foliage_class.instantiate()
		
		add_child(new_foliage)
		new_foliage.set_name("Foliage 1") # figure out why this breaks: haha it's because queue free takes time
		if Engine.is_editor_hint():
			new_foliage.set_owner(get_tree().get_edited_scene_root())
		
		new_foliage.position = select_random_point()
		
		# and rotate IN RADIANS
		new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
		
		new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
		new_foliage.rotation.z = rng.randf_range(0, PI / 12)
		
	
	

func select_random_point():
	if not terrain:
		print("uhoh, no terrain")
		return null


	var x = rng.randf_range(-terrain.size.x / 2, terrain.size.x / 2)
	var z = rng.randf_range(-terrain.size.z / 2, terrain.size.z / 2)
	var y = terrain.heightmap(x, z)
	
	return Vector3(x, y, z)
