@tool
extends Node3D
class_name FoliageGenerator

@export var foliage_subdivisions := 6

@export_tool_button("Generate Foliage") var generate_button = scatter_foliage

var terrain : TerrainGenerator
var water_level := -99999.9
var rng = RandomNumberGenerator.new()

@onready var trees : Array[PackedScene] = [
	preload("res://Testing Assets/Trees/tree_1.tscn"),
	preload("res://Testing Assets/Trees/tree_2.tscn"),
	preload("res://Testing Assets/Trees/tree_3.tscn"),
	preload("res://Testing Assets/Trees/tree_4.tscn"),
	preload("res://Testing Assets/Trees/tree_5.tscn"),
]

@onready var bushes : Array[PackedScene] = [
	preload("res://Testing Assets/Bushes/bush_1.tscn"),
	preload("res://Testing Assets/Bushes/bush_2.tscn"),
	preload("res://Testing Assets/Bushes/bush_3.tscn"),
	preload("res://Testing Assets/Bushes/bush_4.tscn"),
	preload("res://Testing Assets/Bushes/bush_5.tscn"),
	preload("res://Testing Assets/Bushes/bush_6.tscn"),
]

@onready var rocks : Array[PackedScene] = [
	preload("res://Testing Assets/Rocks/rock_1.tscn"),
	preload("res://Testing Assets/Rocks/rock_2.tscn"),
	preload("res://Testing Assets/Rocks/rock_3.tscn"),
	preload("res://Testing Assets/Rocks/rock_4.tscn"),
	preload("res://Testing Assets/Rocks/rock_5.tscn"),
	preload("res://Testing Assets/Rocks/rock_6.tscn"),
]

@onready var abe : Array[PackedScene] = [preload("res://Testing Assets/etc/abe.tscn")]


var initialized = false


func init_foliage():
	rng.seed = Time.get_ticks_usec()
	terrain = get_parent().find_child("*TerrainGenerator*")
	var water = get_parent().find_child("*WaterPlane*")
	if water:
		print("inited")
		water_level = water.position.y
	
	if not terrain:
		print("uhoh, no terrain")
		return
	
	initialized = true
	scatter_foliage()


func scatter_foliage():
	if !initialized:
		init_foliage()
		return
	
	get_tree().call_group("foliage", "queue_free")
	
	for p in range(terrain.get_children().size()):
		var patch = terrain.get_child(p)
		for i in range(foliage_subdivisions):
			for j in range(foliage_subdivisions):
				place_foliage(patch, i, j)
				

func place_foliage(patch, i, j):
	var rand = rng.randf()
	var pos = select_random_point(patch, i, j)
	
	
	if pos.y < water_level:
		if rand < 0.5: #rock only
			return
		
		var new_foliage = create_object(patch, pos, rocks)
		new_foliage.position += rng.randf_range(0, 1) * Vector3.DOWN
		new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
		new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
		new_foliage.rotation.z = rng.randf_range(0, PI / 12)
		return
	
	# chance to skip entirely
	if rand < 0.6:
		return
	
	elif rand < 0.7: # tree
		var new_foliage = create_object(patch, pos, trees)
		new_foliage.position += rng.randf_range(0.5, 1) * Vector3.DOWN
	
		new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
		new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
		new_foliage.rotation.z = rng.randf_range(0, PI / 12)

		
	elif rand < 0.999: # bush
		var new_foliage = create_object(patch, pos, bushes)
	
		new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
		new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
		new_foliage.rotation.z = rng.randf_range(0, PI / 12)
		
	else:
		var new_foliage = create_object(patch, pos, abe)
		new_foliage.position += Vector3.UP

		new_foliage.rotation.y = rng.randf_range(0, 2 * PI)


## select the foliage type and place it in the world
func create_object(patch, cell_pos, scene_array: Array[PackedScene]):
	var type = scene_array.pick_random()
	var new_foliage = type.instantiate()
	
	patch.add_child(new_foliage)
	new_foliage.position = cell_pos
	if Engine.is_editor_hint():
		new_foliage.set_owner(get_tree().get_edited_scene_root())
	
	return new_foliage


# selects within A SINGLE CHUNK!!
func select_random_point(patch, cell_x, cell_z):
	var width = terrain.chunk_size.x / foliage_subdivisions
	var length = terrain.chunk_size.z / foliage_subdivisions
	
	var x = cell_x * width + rng.randf_range(0, width) - terrain.chunk_size.x / 2
	var z = cell_z * length + rng.randf_range(0, length) - terrain.chunk_size.z / 2
	var y = terrain.heightmap(x + patch.position.x, z + patch.position.z)
	
	return Vector3(x, y, z)
