@tool
extends StaticBody3D
class_name TerrainPatch


enum Transition { NONE, NORTH, EAST, SOUTH, WEST }


var terrain_generator: TerrainGenerator
var x_idx: int
var z_idx: int

var subdivisions: int
var size: Vector3
var diagonal_type: TerrainGenerator.DiagonalType
var material : Material
var transition : Transition

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var concave_polygon: ConcavePolygonShape3D


func initialize(terrain_generator: TerrainGenerator, x_idx: int, z_idx: int,
	subdivisions: int, size: Vector3, diagonal_type: TerrainGenerator.DiagonalType,
	material : Material, transition : Transition):
	
	self.terrain_generator = terrain_generator
	self.x_idx = x_idx
	self.z_idx = z_idx
	
	self.subdivisions = subdivisions
	self.size = size
	self.diagonal_type = diagonal_type
	self.material = material
	self.transition = transition


func generate_mesh() -> void:
	print("Started generating patch with ", subdivisions, " subdivision", "." if subdivisions == 1 else "s.")
	var start_time := Time.get_unix_time_from_system()
	
	var children = get_children()
	for child in children:
		child.queue_free()
	
	mesh_instance = MeshInstance3D.new()
	collision_shape = CollisionShape3D.new()
	add_child(mesh_instance)
	add_child(collision_shape)
	if Engine.is_editor_hint() && is_inside_tree():
		mesh_instance.set_owner(get_tree().get_edited_scene_root())
		collision_shape.set_owner(get_tree().get_edited_scene_root())
	
	mesh_instance.mesh = ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# Mesh Generation
	var iterations := 2 ** subdivisions + 1
	var initial := Vector3(-size.x / 2, 0, -size.z / 2) + global_position
	var cell_size := Vector3(size.x / (iterations - 1), size.y, size.z / (iterations - 1))
	for z_index in iterations:
		for x_index in iterations:
			var x := initial.x + x_index * cell_size.x
			var z := initial.z + z_index * cell_size.z
			var y := size.y * terrain_generator.heightmap(x, z)
			verts.append(Vector3(x, y, z) - global_position)
			uvs.append(Vector2(float(x_index) / (iterations - 1), float(z_index) / (iterations - 1)))
			normals.append((terrain_generator.pos_from_map(x, z + cell_size.z) -
							terrain_generator.pos_from_map(x, z - cell_size.z)).cross(
							terrain_generator.pos_from_map(x + cell_size.x, z) -
							terrain_generator.pos_from_map(x - cell_size.x, z)).normalized())
			if x_index > 0 && z_index > 0:
				var vertex_index := x_index * iterations + z_index
				var primary_diagonal := false
				match diagonal_type:
					TerrainGenerator.DiagonalType.SIMPLE:
						primary_diagonal = true
					TerrainGenerator.DiagonalType.ALTERNATING:
						primary_diagonal = (x_index + z_index) % 2 == 0
					TerrainGenerator.DiagonalType.SMOOTHING:
						primary_diagonal = (abs(terrain_generator.heightmap(x, z) -
												terrain_generator.heightmap(x - cell_size.x, z - cell_size.z)) >
											abs(terrain_generator.heightmap(x - cell_size.x, z) -
												terrain_generator.heightmap(x, z - cell_size.z)))
				
				if primary_diagonal:
					indices.append_array(PackedInt32Array([
						vertex_index - iterations - 1, vertex_index - iterations, vertex_index - 1,
						vertex_index - iterations, vertex_index, vertex_index - 1
					]))
				else:
					indices.append_array(PackedInt32Array([
						vertex_index - iterations - 1, vertex_index - iterations, vertex_index,
						vertex_index - iterations - 1, vertex_index, vertex_index - 1
					]))
	
	# Print number of vertices and triangles
	print("Generated patch geometry with ", verts.size(), " vertices and ", indices.size() / 3, " triangles.")

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh_instance.mesh.surface_set_material(0, material)
	
	# Create Packed Vector 3 Array of faces for Concave Polygon 3D 
	var faces := PackedVector3Array()
	# Iterate through each index in the indices array
	for index in indices: # Append the vertex corresponding to each index
		faces.append(verts[index])
	
	# Create the Concave Polygon
	concave_polygon = ConcavePolygonShape3D.new()
	# Set the faces array of the Concave Polygon
	concave_polygon.set_faces(faces)
	# Set the Collision Shape to the Concave Polygon
	collision_shape.shape = concave_polygon;
	
	var duration := Time.get_unix_time_from_system() - start_time;
	print("Completed patch in ", "%0.3f" % duration, " seconds.\n")
