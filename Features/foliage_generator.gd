@tool
extends Node3D
class_name FoliageGenerator

@export_tool_button("Generate Foliage") var generate_button = scatter_foliage
@export var foliage_count = 10


var foliage_class = preload("res://Testing Assets/test_big_tree.tscn")

var terrain : TerrainGenerator
var rng = RandomNumberGenerator.new()


func init_foliage():
	terrain = get_parent().find_child("*TerrainGenerator*")
	
	if not terrain:
		print("uhoh, no terrain")
		return
	
	rng.seed = Time.get_ticks_usec()
	scatter_foliage()

## called the very first time it enters the tree
#func _enter_tree():
	#init_foliage()


# Called when the node enters the scene tree & all it's children are ready
func _ready() -> void:
	init_foliage()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func scatter_foliage():
	for child in get_children():
		child.queue_free()
	
	for i in foliage_count:
		var new_foliage = foliage_class.instantiate()
		
		add_child(new_foliage)
		#new_foliage.set_name("Foliage 1") # figure out why this breaks: haha it's because queue free takes time
		if Engine.is_editor_hint():
			new_foliage.set_owner(get_tree().get_edited_scene_root())
		
		new_foliage.position = select_random_point()
		
		# and rotate IN RADIANS
		new_foliage.rotation.y = rng.randf_range(0, 2 * PI)
		
		new_foliage.rotation.x = rng.randf_range(0, PI / 12) # 1/24 of a circle
		new_foliage.rotation.z = rng.randf_range(0, PI / 12)


func select_random_point():
	var x = rng.randf_range(-terrain.size.x / 2, terrain.size.x / 2)
	var z = rng.randf_range(-terrain.size.z / 2, terrain.size.z / 2)
	var y = terrain.heightmap(x, z)
	
	return Vector3(x, y, z)
