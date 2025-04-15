@tool
extends Node3D
class_name TerrainGenerator

enum DiagonalType {SIMPLE, ALTERNATING, SMOOTHING}

@export_tool_button("Generate Terrain") var generate_button = generate_mesh


@export_group("Chunks")


@export var chunk_size := Vector3(10, 5, 10) :
	set(value):
		if chunk_size != value:
			chunk_size = value
			update_size()
			if Engine.is_editor_hint() && is_inside_tree():
				generate_mesh()


@export_range(1, 20) var edge_chunks := 1 :
	set(value):
		if edge_chunks != value:
			edge_chunks = value
			update_size()
			if Engine.is_editor_hint() && is_inside_tree():
				generate_mesh()


@export_group("Noise")


@export_range(0.1, 20, 0.1) var horizontal_scale := 10.0 :
	set(value):
		if horizontal_scale != value:
			horizontal_scale = value
			if Engine.is_editor_hint() && is_inside_tree():
				generate_mesh()


@export_group("LOD")


@export_range(0, 8) var subdivisions := 6 :
	set(value):
		if subdivisions != value:
			subdivisions = value
			if Engine.is_editor_hint() && is_inside_tree():
				generate_mesh()


@export var diagonal_type := DiagonalType.SMOOTHING :
	set(value):
		if diagonal_type != value:
			diagonal_type = value
			if Engine.is_editor_hint() && is_inside_tree():
				generate_mesh()


@export_group("Material")


@export var material : Material = preload("res://Materials/basic.tres") :
	set(value):
		if material != value:
			material = value
			if Engine.is_editor_hint() && is_inside_tree():
				generate_mesh()


var height_noise := FastNoiseLite.new()
var size := chunk_size * Vector3(edge_chunks, 1, edge_chunks)

const PATCH = preload("res://Features/terrain_patch.tscn")
var patches


func update_size() -> void:
	size = Vector3(edge_chunks, 1, edge_chunks) * chunk_size


func heightmap(x: float, z: float) -> float:
	return (height_noise.get_noise_2d(x * horizontal_scale, z * horizontal_scale)) * size.y


func pos_from_map(x: float, z:float) -> Vector3:
	return Vector3(x, heightmap(x, z), z)


func _ready() -> void:
	generate_mesh()


func coord_from_idx(idx: int) -> Vector2:
	if idx == 0:
		return Vector2(0,0)
	
	var cycle = int(ceil(floor(sqrt(idx)) / 2.0))
	var idx_into_cycle = int(idx - (4.0 * cycle * (cycle - 1.0) + 1.0))
	var turn = int(floor(float(idx_into_cycle) / (2.0 * cycle)))
	const corners = [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]
	const steps = [Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0), Vector2(0, 1)]
	
	return cycle * corners[turn] + (1 + idx_into_cycle % (2 * cycle)) * steps[turn]


func get_x_dist(idx: int) -> float:
	return idx - float(edge_chunks - 1) / 2


func get_z_dist(idx: int) -> float:
	return idx - float(edge_chunks - 1) / 2


func get_subdivisions(x_idx: int, z_idx: int) -> int:
	var dist = max(abs(get_x_dist(x_idx)), abs(get_x_dist(z_idx)))
	
	var chunk_subdivisions = subdivisions
	if dist >= 3.5:
		return chunk_subdivisions - 2
	if dist >= 1.5:
		return chunk_subdivisions - 1
	
	return chunk_subdivisions


func generate_mesh() -> void:
	print("Started generating terrain...\n")
	var start_time := Time.get_unix_time_from_system()
	
	height_noise.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	height_noise.set_seed(randi())
	
	var children = get_children()
	for child in children:
		child.queue_free()
	
	var initial_position = Vector3(chunk_size.x, 0, chunk_size.z) * (edge_chunks - 1) * -0.5
	
	patches = []
	for z in edge_chunks:
		patches.append([])
		for x in edge_chunks:
			patches[z].append(null)
	
	for i in edge_chunks ** 2:
		var coord = coord_from_idx(i) + Vector2((edge_chunks - 1) / 2, (edge_chunks - 1) / 2)
		var x = coord.x
		var z = coord.y
		
		var chunk_subdivisions = get_subdivisions(x, z)
		
		var x_dist = get_x_dist(x)
		var z_dist = get_z_dist(z)
		var north_south = abs(x_dist) < abs(z_dist)
		
		var transition := TerrainPatch.Transition.NONE
		if abs(x_dist) == abs(z_dist):
			pass
		elif north_south:
			if z_dist < 0 && get_subdivisions(x, z + 1) != chunk_subdivisions:
				transition = TerrainPatch.Transition.SOUTH
			if z_dist > 0 && get_subdivisions(x, z - 1) != chunk_subdivisions:
				transition = TerrainPatch.Transition.NORTH
		else:
			if x_dist < 0 && get_subdivisions(x + 1, z) != chunk_subdivisions:
				transition = TerrainPatch.Transition.EAST
			if x_dist > 0 && get_subdivisions(x - 1, z) != chunk_subdivisions:
				transition = TerrainPatch.Transition.WEST
		
		var patch = PATCH.instantiate()
		patches[z].set(x, patch)
		patch.initialize(self, x, z, chunk_subdivisions, chunk_size,
		diagonal_type, material, transition)
		
		add_child(patch)
		patch.position = initial_position + chunk_size * Vector3(x, 0, z)
		if Engine.is_editor_hint() && is_inside_tree():
			patch.set_owner(get_tree().get_edited_scene_root())
		
		patch.generate_mesh()
	
	var duration := Time.get_unix_time_from_system() - start_time;
	print("Completed terrain generation in ", "%0.3f" % duration, " seconds.\n\n")
